use warnings;
use strict;

package Jifty;

=head1 NAME

Jifty -- Just Finally Do It

=head1 DESCRIPTION

Yet another web framework.  

=cut

use Jifty::Everything;
use Jifty::DBI::Handle;
use UNIVERSAL::require;
use YAML;
use File::Spec;
use File::Basename;
use Log::Log4perl;
use Hash::Merge;
Hash::Merge::set_behavior( 'RIGHT_PRECEDENT' );

require Module::Pluggable;

use File::Basename();
use base qw/Jifty::Object/;

use vars qw/$HANDLE $CONFIG $SERIAL/;

=head1 METHODS

=head2 new PARAMHASH

This class method instantiates a new C<Jifty> object. This object deals
with configuration files, logging and database handles for the system.

=head3 Arguments

=over

=item config_file

The relative or absolute path to this application's default
configuration file.  This value can be overridden with the
C<JIFTY_CONFIG> environment variable -- see below.

=item no_handle

If this is set to true, Jifty will not connect to a database.  Only use
this if you're about to drop the database or do something extreme like
that; most of Jifty expects the handle to exist.  Defaults to false.

=back

=head3 Configuration

This method will load the main configuration file for the application
and use that to find a vendor configuration file. (If it doesn't find
a framework variable named 'VendorConfig', it will use the
C<JIFTY_VENDOR_CONFIG> environment variable.

After loading the vendor configuration file (if it exists), the
framework will look for a site configuration file, specified in either
the framework's C<SiteConfig> or the C<JIFTY_SITE_CONFIG> environment
variable.

Values in the site configuration file clobber those in the vendor
configuration file. Values in the vendor configuration file clobber
those in the application configuration file.

=cut

sub new {
    my $ignored_class = shift;

    my %args = (
        config_file => undef,
        no_handle => 0,
        logger_component => undef,
        @_
    );

    Jifty->load_configuration($args{'config_file'});
    Jifty->_log_init($args{'logger_component'});
    unless ($args{'no_handle'}) {
        Jifty->_setup_handle();
        Jifty->check_db_schema();
         }
    my $ApplicationClass = Jifty->framework_config('ApplicationClass');
    $ApplicationClass->require;

    Module::Pluggable->import(
        search_path =>
          [ map { $ApplicationClass . "::" . $_ } 'Model', 'Action', 'Notification' ],
        require => 1
    );
    Jifty->plugins;
}


=head2 framework_config VARIABLE

Get the framework configuration variable C<VARIABLE>.  

If the value begins and ends with %, converts it with
C<absolute_path> to an absolute path.  (This is unnecessary for most
configuration variables which specify files, but is needed for variables such as
C<MailerArgs> that only sometimes specify files.)

=cut

sub framework_config {
  my $class = shift;
  my $var = shift;
  
  Jifty->_get_config('framework', $var);
}


=head2 app_config VARIABLE

Get the application configuration variable C<VARIABLE>.

If the value begins and ends with %, converts it with
C<absolute_path> to an absolute path.  (This is unnecessary for most
configuration variables which specify files, but is needed for variables such as
C<MailerArgs> that only sometimes specify files.)

=cut

sub app_config {
  my $class = shift;
  my $var = shift;
  
  Jifty->_get_config('application', $var);
}

sub _get_config {
  my $class = shift;
  my $section = shift;
  my $var = shift;
  
  Jifty->_config->{$section}->{$var};
}


=head2 load_configuration FILE

Loads all configuration files. See the docs for C<new> to see how this
works

=cut

sub load_configuration {
    my $class = shift;
    my $file = shift;


    my ( $app_config, $vendor_config, $site_config, $config );

    $file = $ENV{'JIFTY_CONFIG'} ||  dirname($0).'/../etc/config.yml';
    # Die unless we find it
    die "Can't find configuration file $file" unless -f $file and -r $file;
    $app_config =
      Jifty->load_config_file( $file ) ;

    # Load the $app_config so we know where to find the vendor config file
    Jifty->_config($app_config);

    $vendor_config =
      Jifty->load_config_file( Jifty->absolute_path( Jifty->framework_config('VendorConfig')
          || $ENV{'JIFTY_VENDOR_CONFIG'} ));

    # First, we load the app and vendor configs. This way, we can
    # figure out if we have a special name for the siteconfig file
    $config =  Hash::Merge::merge( $app_config, $vendor_config );
    Jifty->_config($config);

    $site_config =
      Jifty->load_config_file( Jifty->absolute_path( Jifty->framework_config('SiteConfig')
          || $ENV{'JIFTY_SITE_CONFIG'} ));

    $config = Hash::Merge::merge( $config, $site_config  );
    Jifty->_config($config);

}


=head2 load_config_file PATH

Loads a YAML configuration file and returns a hashref to that file's
data.

=cut

sub load_config_file {

    my $self = shift;
    my $file = shift;
    # only try to load files that exist
    return {} unless ($file && -f $file);
    my $hashref = YAML::LoadFile($file )
        or die "I couldn't load config file $file: $!";

    $hashref = $self->_absolutify($hashref);
    return $hashref;
} 

# Does a DFS, turning all leaves that look like %paths% into absolute paths.
sub _absolutify {
    my $self = shift;
    my $datum = shift;

    if (ref $datum eq 'ARRAY') {
        return [ map { $self->_absolutify($_) } @$datum ];
    } elsif (ref $datum eq 'HASH') {
        for my $key (keys %$datum) {
            my $new_val = $self->_absolutify( $datum->{$key} );
            $datum->{$key} = $new_val;
        } 
        return $datum;
    } elsif (ref $datum) {
        return $datum;
    } else {
        if (defined $datum and $datum =~ /^%(.+)%$/) {
            $datum = Jifty->absolute_path($1);
        }
        return $datum;
    } 
} 


# Getter/setter for config hash
sub _config  {
    my $class = shift;
    $CONFIG = shift if (@_);
    return $CONFIG;
}


=head2 absolute_path PATH

C<absolute_path> converts PATH into an absolute path, relative to the
parent of the parent of the executable.  (This assumes that the
executable is in C<I<ApplicationRoot>/bin/>.)  This can be called as
an object or class method.

=cut

sub absolute_path {
    my $class = shift;
    my $path = shift;

    my @root = File::Spec->splitdir( File::Spec->rel2abs($0));
    pop @root; # filename
    pop @root; # bin
    my $root = File::Spec->catdir(@root);
    
    return File::Spec->rel2abs($path, $root);
} 


# Set up logging
sub _log_init {
    my $class = shift;
    my $component = shift;
    $component = '' unless defined $component;
    
    my $log_config = Jifty->absolute_path( Jifty->framework_config('LogConfig'));
    if (defined Jifty->framework_config('LogReload')) {
        Log::Log4perl->init_and_watch($log_config, Jifty->framework_config('LogReload'));
    } elsif (-f $log_config and -r $log_config)  {
        Log::Log4perl->init($log_config);
    } 

    else {
        my %default = (
        "log4perl.rootLogger"       => "ALL,Screen",
        'log4perl.appender.Screen'         => 'Log::Log4perl::Appender::Screen',
        'log4perl.appender.Screen.stderr'  => 0,
        'log4perl.appender.Screen.layout' => 'Log::Log4perl::Layout::SimpleLayout');

        Log::Log4perl->init(\%default);


    }
    my $logger = Log::Log4perl->get_logger($component);
    $SIG{__WARN__} = sub {
        # This caller_depth line tells Log4perl to report
        # the error as coming from on step further up the
        # caller chain (ie, where the warning originated)
        # instead of from the $logger->warn line.
        local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;

        # If the logger has been taken apart by global destruction,
        # don't try to use it to log warnings
        $logger->warn(@_) if Log::Log4perl->initialized;
    };
    if (0) {
    $SIG{__DIE__} = sub {
        # This caller_depth line tells Log4perl to report
        # the error as coming from on step further up the
        # caller chain (ie, where the die originated)
        # instead of from the $logger->logdie line.

        local $Log::Log4perl::caller_depth =
            $Log::Log4perl::caller_depth + 1;
        $logger->logdie(@_);
    };
    }
}


# Setup database handle based on config data
sub _setup_handle {
    my $class = shift;
    
    my $handle = Jifty::DBI::Handle->new();

    if (Jifty->framework_config('Database')->{Driver} eq 'Oracle') {
        $ENV{'NLS_LANG'} = "AMERICAN_AMERICA.AL32UTF8";
        $ENV{'NLS_NCHAR'} = "AL32UTF8";
    }


    my %db_config = %{Jifty->framework_config('Database')};
    my %lc_db_config;
    for (keys %db_config) {
        $lc_db_config{lc($_)} = $db_config{$_};
    }
    $handle->connect( %lc_db_config );


    $handle->dbh->{LongReadLen} = Jifty->framework_config('MaxAttachmentSize') || '10000000';
     
    Jifty->handle($handle);
}


=head2 handle

Get/set our Jifty::DBI::Handle object

=cut

sub handle  {
    my $class = shift;
    $HANDLE = shift if (@_);
    return $HANDLE;
}


=head2 check_db_schema

Make sure that we have a recent enough database schema.  If we don't,
then error out.

=cut

sub check_db_schema {

        my $appv = version->new( Jifty->framework_config('Database')->{'Version'} );
        my $dbv  =  Jifty::Model::Schema->new->in_db;
        die "Schema has no version in the database; perhaps you need to run bin/schema --install?\n"
          unless defined $dbv;

        die "Schema version in database ($dbv) doesn't match application schema version ($appv)\n".
          "Please run bin/schema to upgrade the database.\n"
            unless $appv == $dbv;
   
        } 

=head2 serial 

Returns an integer, guaranteed to be unique within the runtime of a
particular process (ie, within the lifetime of Jifty.pm).  There's no
sort of global uniqueness guarantee, but it should be good enough for
generating things like moniker names.

=cut

sub serial {
    my $class = shift;
    # We don't use a lexical for the serial number, because then it would be
    # reset on module refresh
    $SERIAL ||= 0;
    return ++$SERIAL; # Start at 1.
} 

=head2 framework

Returns the current L<Jifty::Web> object.

=cut

sub framework {
    return $HTML::Mason::Commands::framework;
} 

=head2 mason

Returns the current L<HTML::Mason::Request> object (equivalent to
C<< Jifty->framework->mason >>).

=cut

sub mason {
    my $class = shift;
    return $class->framework->mason;
} 

=head1 AUTHOR

Various folks at BestPractical Solutions, LLC.

=cut

1;
