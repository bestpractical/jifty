use warnings;
use strict;

package Jifty::Config;

=head1 NAME

Jifty::Config -- wrap a jifty configuration file

=head1 DESCRIPTION


=cut

use Jifty::Util;
use Jifty::YAML;
use File::Spec;
use File::Basename;
use Log::Log4perl;
use Hash::Merge;
Hash::Merge::set_behavior('RIGHT_PRECEDENT');

require Module::Pluggable;

use File::Basename();
use base qw/Class::Accessor/;

use vars qw/$CONFIG/;

__PACKAGE__->mk_accessors(qw/stash/);

=head1 METHODS

=head2 new PARAMHASH

This class method instantiates a new C<Jifty::Config> object. This
object deals with configuration files.  

PARAMHASH currently takes a single option

=over

=item load_config

This boolean defaults to true. If true, L</load> will be called upon initialization.

=back


=cut

sub new {
    my $proto = shift;
    my %args = ( load_config => 1,
                 @_ 
             );
    my $self  = {};
    bless $self, $proto;
    $self->stash( {} );

    $self->load() if ($args{'load_config'});
    return $self;
}

=head2 load


Jifty first loads the main
configuration file for the application, looking for the
C<JIFTY_CONFIG> environment variable or C<etc/config.yml> under the
application's base directory.

It uses the main configuration file to find a vendor configuration
file -- if it doesn't find a framework variable named 'VendorConfig',
it will use the C<JIFTY_VENDOR_CONFIG> environment variable.

After loading the vendor configuration file (if it exists), the
framework will look for a site configuration file, specified in either
the framework's C<SiteConfig> or the C<JIFTY_SITE_CONFIG> environment
variable.

Values in the site configuration file clobber those in the vendor
configuration file. Values in the vendor configuration file clobber
those in the application configuration file.

Once we're all done loading from files, several defaults are
assumed based on the name of the application -- see L</guess>. 

After we have the config file, we call the coderef in C<$Jifty::Config::postload>,
if it exists.

If the value begins and ends with %, converts it with
C<Jifty::Util/absolute_path> to an absolute path.  (This is
unnecessary for most configuration variables which specify files, but
is needed for variables such as C<MailerArgs> that only sometimes
specify files.)

=cut

sub load {
    my $self = shift;


    my $file = $ENV{'JIFTY_CONFIG'} || Jifty::Util->app_root . '/etc/config.yml';

    my $app;

    # Override anything in the default guessed config with anything from a config file
    if ( -f $file and -r $file ) {
        $app = $self->load_file($file);
        $app = Hash::Merge::merge( $self->stash, $app );

        # Load the $app so we know where to find the vendor config file
        $self->stash($app);
    }
    my $vendor = $self->load_file(
        Jifty::Util->absolute_path(
            $self->framework('VendorConfig') || $ENV{'JIFTY_VENDOR_CONFIG'}
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

    # Merge guessed values in for anything we didn't explicitly define
    # Whatever's in the stash overrides anything we guess
    $self->stash( Hash::Merge::merge( $self->guess, $self->stash ));


    # Finally, check for global postload hooks (these are used by the
    # test harness)
    $self->$Jifty::Config::postload()
      if $Jifty::Config::postload;
}

=head2 framework VARIABLE

Get the framework configuration variable C<VARIABLE>.  

=cut

sub framework {
    my $self = shift;
    my $var  = shift;

    $self->_get( 'framework', $var );
}

=head2 app VARIABLE

Get the application configuration variable C<VARIABLE>.

=cut

sub app {
    my $self = shift;
    my $var  = shift;

    $self->_get( 'application', $var );
}

sub _get {
    my $self    = shift;
    my $section = shift;
    my $var     = shift;

    return  $self->stash->{$section}->{$var} 
}


=head2 guess

Attempts to guess (and return) a configuration hash based solely
on what we already know. (Often, in the complete absence of
a configuration file).  It uses the name of the directory containing
the Jifty binary as a default for C<ApplicationName> if it can't find one.

=cut

sub guess {
    my $self = shift;

    # Walk around a potential loop by calling guess to get the app name
    my $app_name;
    if (@_) {
        $app_name = shift;
    } elsif ($self->stash->{framework}->{ApplicationName}) {
        $app_name =  $self->stash->{framework}->{ApplicationName};
    } else {
        $app_name =  Jifty::Util->default_app_name;
    }

    my $app_class = $app_name;
    $app_class =~ s/-/::/g;
    my $db_name = lc $app_name;
    $db_name =~ s/-/_/g;
    return {
        framework => {
            AdminMode        => 1,
            DevelMode        => 1,
            ActionBasePath   => $app_class . "::Action",
            ApplicationClass => $app_class,
            CurrentUserClass => $app_class . "::CurrentUser",
            ApplicationName  => $app_name,
            Database         => {
                Database =>  $db_name,
                Driver   => "SQLite",
                Host     => "localhost",
                Password => "",
                User     => "",
                Version  => "0.0.1",
                RecordBaseClass => 'Jifty::DBI::Record::Cachable'
            },
            Mailer     => 'Sendmail',
            MailerArgs => [],
            Web        => {
                DefaultStaticRoot => Jifty::Util->share_root . '/web/static',
                DefaultTemplateRoot => Jifty::Util->share_root . '/web/templates',
                Port => '8888',
                BaseURL => 'http://localhost',
                SessionDir  => "var/session",
                DataDir     => "var/mason",
                StaticRoot   => "web/static",
                TemplateRoot => "web/templates",
                ServeStaticFiles => 1,
                MasonConfig => {
                    autoflush    => 0,
                    error_mode   => 'fatal',
                    error_format => 'text',
                    default_escape_flags => 'h',
                },
                Globals      => [],
            },
        },
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
    return {} unless ( $file && -f $file );
    my $hashref = Jifty::YAML::LoadFile($file)
        or die "I couldn't load config file $file: $!";

    $hashref = $self->_expand_relative_paths($hashref);
    return $hashref;
}


# Does a DFS, turning all leaves that look like C<%paths%> into absolute paths.
sub _expand_relative_paths {
    my $self  = shift;
    my $datum = shift;

    if ( ref $datum eq 'ARRAY' ) {
        return [ map { $self->_expand_relative_paths($_) } @$datum ];
    } elsif ( ref $datum eq 'HASH' ) {
        for my $key ( keys %$datum ) {
            my $new_val = $self->_expand_relative_paths( $datum->{$key} );
            $datum->{$key} = $new_val;
        }
        return $datum;
    } elsif ( ref $datum ) {
        return $datum;
    } else {
        if ( defined $datum and $datum =~ /^%(.+)%$/ ) {
            $datum = Jifty::Util->absolute_path($1);
        }
        return $datum;
    }
}

=head1 AUTHOR

Various folks at BestPractical Solutions, LLC.

=cut

1;
