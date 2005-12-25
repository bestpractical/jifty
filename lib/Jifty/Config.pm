use warnings;
use strict;

package Jifty::Config;

=head1 NAME

Jifty::Config -- wrap a jifty configuration file

=head1 DESCRIPTION


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
use base qw/Class::Accessor/;

use vars qw/$CONFIG/;

__PACKAGE__->mk_accessors(qw/stash/);



=head1 METHODS

=head2 new PARAMHASH

This class method instantiates a new C<Jifty> object. This object deals
with configuration files, logging and database handles for the system.

=head3 Arguments

=over

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
    my $proto = shift;
    my $self = {};
    bless $self, $proto;
    $self->load();
    return $self;
}


=head2 framework VARIABLE

Get the framework configuration variable C<VARIABLE>.  

If the value begins and ends with %, converts it with
C<Jifty::Util/absolute_path> to an absolute path.  (This is unnecessary for most
configuration variables which specify files, but is needed for variables such as
C<MailerArgs> that only sometimes specify files.)

=cut

sub framework {
  my $self = shift;
  my $var = shift;
  
  $self->_get('framework', $var);
}


=head2 app VARIABLE

Get the application configuration variable C<VARIABLE>.

If the value begins and ends with %, converts it with
C<Jifty::Util/absolute_path> to an absolute path.  (This is unnecessary for most
configuration variables which specify files, but is needed for variables such as
C<MailerArgs> that only sometimes specify files.)

=cut

sub app {
  my $self = shift;
  my $var = shift;
  
  $self->_get('application', $var);
}

sub _get {
  my $self = shift;
  my $section = shift;
  my $var = shift;
  
  $self->stash->{$section}->{$var};
}


=head2 load 

Loads all configuration files. See the docs for C<new> to see how this
works.

=over


It looks for ENV{'JIFTY_CONFIG'} or  etc/config.yml in this 
app's base directory.

=back

=cut


sub load {
    my $self = shift;

    $self->stash($self->guess);

    my $file = $ENV{'JIFTY_CONFIG'} || dirname($0) . '/../etc/config.yml';

    my $app;
    # Override anything in the default guessed config with anything from a config file
    if ( -f $file and -r $file ) {
        $app = $self->load_file($file);
        $app = Hash::Merge::merge($self->stash, $app );
        # Load the $app so we know where to find the vendor config file
        $self->stash($app);
    }
    my $vendor = $self->load_file(
        Jifty::Util->absolute_path(
            $self->framework('VendorConfig')
                || $ENV{'JIFTY_VENDOR_CONFIG'}
        )
    );

    # First, we load the app and vendor configs. This way, we can
    # figure out if we have a special name for the siteconfig file
    my $config = Hash::Merge::merge( $self->stash, $vendor );
    $self->stash($config);

    my $site = $self->load_file(
        Jifty::Util->absolute_path(
            $self->framework('SiteConfig') || $ENV{'JIFTY_SITE_CONFIG'}
        )
    );

    $config = Hash::Merge::merge( $self->stash, $site );
    $self->stash($config);

}

=head2 guess

Attempts to guess (and return) a configuration hash, in the absence of
a configuration file.  It uses the name of the directory containing
the Jifty binary as the name of the application and database.

=cut

sub guess {
    my $self = shift;

    require FindBin;
    my $path = $FindBin::Bin;
    my ($name) = $path =~ m{.*/([^/]+)/(?:bin|t)} or die "Can't guess application name from $path";

    return {
            framework => {
                          ActionBasePath   => $name."::Action",
                          ApplicationClass => $name,
                          ApplicationName  => $name,
                          Database => {
                                       Database => lc $name,
                                       Driver   => "Pg",
                                       Host     => "localhost",
                                       Password => "",
                                       User     => "postgres",
                                       Version  => "0.0.1",
                                      },
                          Web => {
                                  StaticRoot   => "web/static",
                                  TemplateRoot => "web/templates",
                                 }
                         }
           };

}


=head2 load_file PATH

Loads a YAML configuration file and returns a hashref to that file's
data.

=cut

sub load_file {

    my $self = shift;
    my $file = shift;
    # only try to load files that exist
    return {} unless ($file && -f $file);
    my $hashref = YAML::LoadFile($file )
        or die "I couldn't load config file $file: $!";

    $hashref = $self->_expand_relative_paths($hashref);
    return $hashref;
} 

=head2 _expand_relative_paths

Does a DFS, turning all leaves that look like %paths% into absolute paths.

=cut

sub _expand_relative_paths {
    my $self = shift;
    my $datum = shift;

    if (ref $datum eq 'ARRAY') {
        return [ map { $self->_expand_relative_paths($_) } @$datum ];
    } elsif (ref $datum eq 'HASH') {
        for my $key (keys %$datum) {
            my $new_val = $self->_expand_relative_paths( $datum->{$key} );
            $datum->{$key} = $new_val;
        } 
        return $datum;
    } elsif (ref $datum) {
        return $datum;
    } else {
        if (defined $datum and $datum =~ /^%(.+)%$/) {
            $datum = Jifty::Util->absolute_path($1);
        }
        return $datum;
    } 
} 


=head1 AUTHOR

Various folks at BestPractical Solutions, LLC.

=cut

1;
