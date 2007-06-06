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

use File::Basename();
use base qw/Class::Accessor::Fast/;

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
variable. (Usually in C<etc/site_config.yml>.)

After loading the site configuration file (if it exists), the
framework will look for a test configuration file, specified in either
the framework's C<TestConfig> or the C<JIFTY_TEST_CONFIG> environment
variable.

Values in the test configuration will clobber the site configuration.
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

    $self->stash( Hash::Merge::merge( $self->_default_config_files, $self->stash ));

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

    my $test = $self->load_file(
        Jifty::Util->absolute_path(
            $self->framework('TestConfig') || $ENV{'JIFTY_TEST_CONFIG'}
        )
    );
    $config = Hash::Merge::merge( $self->stash, $test );
    $self->stash($config);

    # Merge guessed values in for anything we didn't explicitly define
    # Whatever's in the stash overrides anything we guess
    $self->stash( Hash::Merge::merge( $self->guess, $self->stash ));
    
    # There are a couple things we want to guess that we don't want
    # getting stuck in a default config file for an app
    $self->stash( Hash::Merge::merge( $self->defaults, $self->stash));

    $self->stash($self->update_config($self->stash));


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


sub _default_config_files {
    my $self = shift;
    my $config  = {
        framework => {
            SiteConfig => 'etc/site_config.yml'
        }
    };
    return $self->_expand_relative_paths($config);
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

    my $app_class =  $self->stash->{framework}->{ApplicationClass} ||$app_name;
    $app_class =~ s/-/::/g;
    my $db_name = lc $app_name;
    $db_name =~ s/-/_/g;
    my $app_uuid = Jifty::Util->generate_uuid;

    my $guess = {
        framework => {
            AdminMode        => 1,
            DevelMode        => 1,
	    SkipAccessControl => 0,
            ApplicationClass => $app_class,
            TemplateClass    => $app_class."::View",
            ApplicationName  => $app_name,
            ApplicationUUID  => $app_uuid,
            LogLevel         => 'INFO',
            PubSub           => {
                Enable => undef,
                Backend => 'Memcached',
                    },
            Database         => {
                Database =>  $db_name,
                Driver   => "SQLite",
                Host     => "localhost",
                Password => "",
                User     => "",
                Version  => "0.0.1",
                RecordBaseClass => 'Jifty::DBI::Record::Cachable',
                CheckSchema => '1'
            },
            Mailer     => 'Sendmail',
            MailerArgs => [],
            L10N       => {
                PoDir => "share/po",
            },
            Web        => {
                Port => '8888',
                BaseURL => 'http://localhost',
                DataDir     => "var/mason",
                StaticRoot   => "share/web/static",
                TemplateRoot => "share/web/templates",
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

    return $self->_expand_relative_paths($guess);

}


=head2 initial_config

Returns a default guessed config for a new application

=cut

sub initial_config {
    my $self = shift;
    my $guess = $self->guess(@_);
    $guess->{'framework'}->{'ConfigFileVersion'} = 2;

    # These are the plugins which new apps will get by default
            $guess->{'framework'}->{'Plugins'} = [
              { LetMe               => {}, },
                { SkeletonApp            => {}, },
                { REST               => {}, },
                { Halo               => {}, },
                { ErrorTemplates     => {}, },
                { OnlineDocs         => {}, },
                { CompressedCSSandJS => {}, },
                { AdminUI            => {}, }
                ];
    return $guess;
}



=head2 update_config  $CONFIG

Takes an application's configuration as a hashref.  Right now, it just sets up
plugins that match an older jifty version's defaults

=cut

sub update_config {
    my $self = shift;
    my $config = shift;
    if ( $config->{'framework'}->{'ConfigFileVersion'} <2) {
            # These are the plugins which old apps expect because their
            # features used to be in the core.
            unshift (@{$config->{'framework'}->{'Plugins'}}, 
                { SkeletonApp            => {}, },
                { REST               => {}, },
                { Halo               => {}, },
                { ErrorTemplates     => {}, },
                { OnlineDocs         => {}, },
                { CompressedCSSandJS => {}, },
                { AdminUI            => {}, }
            );
    }

    return $config;
}



=head2 defaults

We have a couple default values that shouldn't be included in the
"guessed" config, as that routine is used when initializing a new 
application. Generally, these are platform-specific file locations.

=cut

sub defaults {
    my $self = shift;
    return {
        framework => {
            ConfigFileVersion => '1',
            L10N => {
                DefaultPoDir => Jifty::Util->share_root . '/po',
            },
            Web => {
                DefaultStaticRoot => Jifty::Util->share_root . '/web/static',
                DefaultTemplateRoot => Jifty::Util->share_root . '/web/templates',
            },
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
