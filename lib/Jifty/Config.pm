use warnings;
use strict;

package Jifty::Config;

=head1 NAME

Jifty::Config - the configuration handler for Jifty

=head1 SYNOPSIS

  my $app_name = Jifty->config->framework('ApplicationName');
  my $frobber  = Jifty->config->app('PreferredFrobnicator');

=head1 DESCRIPTION

This class is automatically loaded during Jifty startup. It contains the configuration information loaded from the F<config.yml> file (generally stored in the F<etc> directory of your application, but see L</load> for the details). This configuration file is stored in L<YAML> format.

This configuration file contains two major sections named "C<framework>" and "C<application>". The framework section contains Jifty-specific configuration options and the application section contains whatever configuration options you want to use with your application. (I.e., if there's any configuration information your application needs to know at startup, this is a good place to put it.)

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

In general, you never need to call this, just use:

  Jifty->config

in your application.

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

    # Setup the initially empty stash
    $self->stash( {} );

    # Load from file unless they tell us not to
    $self->load() if ($args{'load_config'});
    return $self;
}

=head2 load

Jifty first loads the main configuration file for the application, looking for
the C<JIFTY_CONFIG> environment variable or C<etc/config.yml> under the
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

Note that the test config may be drawn from several files if you use
L<Jifty::Test>. See the documentation of L<Jifty::Test::load_test_configs>.

Values in the test configuration will clobber the site configuration.
Values in the site configuration file clobber those in the vendor
configuration file. Values in the vendor configuration file clobber
those in the application configuration file. (See L</WHY SO MANY FILES> for a deeper search for truth on this matter.)

Once we're all done loading from files, several defaults are
assumed based on the name of the application -- see L</guess>. 

After we have the config file, we call the coderef in C<$Jifty::Config::postload>, if it exists. This last bit is generally used by the test harness to do a little extra work.

B<SPECIAL PER-VALUE PROCESSING:> If a value begins and ends with "%" (e.g.,
"%bin/foo%"), converts it with C<Jifty::Util/absolute_path> to an absolute path.
This is typically unnecessary, but helpful for configuration variables such as C<MailerArgs> that only sometimes specify files.

=cut

sub load {
    my $self = shift;

    # Add the default configuration file locations to the stash
    $self->stash( Hash::Merge::merge( $self->_default_config_files, $self->stash ));

    # Calculate the location of the application etc/config.yml
    my $file = $ENV{'JIFTY_CONFIG'} || Jifty::Util->app_root . '/etc/config.yml';

    my $app;

    # Start by loading application configuration file
    if ( -f $file and -r $file ) {
        $app = $self->load_file($file);
        $app = Hash::Merge::merge( $self->stash, $app );

        # Load the $app so we know where to find the vendor config file
        $self->stash($app);
    }

    # Load the vendor configuration file
    my $vendor = $self->load_file(
        Jifty::Util->absolute_path(
            $self->framework('VendorConfig') || $ENV{'JIFTY_VENDOR_CONFIG'}
        )
    );

    # Merge the app config with vendor config, vendor taking precedent
    my $config = Hash::Merge::merge( $self->stash, $vendor );
    $self->stash($config);

    # Load the site configuration file
    my $site = $self->load_file(
        Jifty::Util->absolute_path(
            # Note: $ENV{'JIFTY_SITE_CONFIG'} is already considered
            #       in ->_default_config_files(), but we || here again
            #       in case someone overrided _default_config_files().
            $self->framework('SiteConfig') || $ENV{'JIFTY_SITE_CONFIG'}
        )
    );

    # Merge the app, vendor, and site config, site taking precedent
    $config = Hash::Merge::merge( $self->stash, $site );
    $self->stash($config);

    # Load the test configuration file
    my $test = $self->load_file(
        Jifty::Util->absolute_path(
            $self->framework('TestConfig') || $ENV{'JIFTY_TEST_CONFIG'}
        )
    );

    # Merge the app, vendor, site and test config, test taking precedent
    $config = Hash::Merge::merge( $self->stash, $test );
    $self->stash($config);

    # Merge guessed values in for anything we didn't explicitly define
    # Whatever's in the stash overrides anything we guess
    $self->stash( Hash::Merge::merge( $self->guess, $self->stash ));
    
    # There are a couple things we want to guess that we don't want
    # getting stuck in a default config file for an app
    $self->stash( Hash::Merge::merge( $self->defaults, $self->stash));

    # Bring old configurations up to current expectations
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

# A teeny helper for framework and app
sub _get {
    my $self    = shift;
    my $section = shift;
    my $var     = shift;

    return  $self->stash->{$section}->{$var} 
}

# Sets up the initial location of the site configuration file
sub _default_config_files {
    my $self = shift;
    my $config  = {
        framework => {
            SiteConfig => (
                $ENV{JIFTY_SITE_CONFIG} || 'etc/site_config.yml'
            )
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

    # First try at guessing the app name...
    my $app_name;

    # Was it passed to this method?
    if (@_) {
        $app_name = shift;
    }

    # Is it already in the stash?
    elsif ( $self->stash->{framework}->{ApplicationName} ) {
        $app_name = $self->stash->{framework}->{ApplicationName};
    }

    # Finally, just guess from the application root
    else {
        $app_name = Jifty::Util->default_app_name;
    }

    # Setup the application class name based on the application name
    my $app_class = $self->stash->{framework}->{ApplicationClass}
        || $app_name;
    $app_class =~ s/-/::/g;
    my $db_name = lc $app_name;
    $db_name =~ s/-/_/g;
    my $app_uuid = Jifty::Util->generate_uuid;

    # Build up the guessed configuration
    my $guess = {
        framework => {
            AdminMode         => 1,
            DevelMode         => 1,
            SkipAccessControl => 0,
            ApplicationClass  => $app_class,
            TemplateClass     => $app_class . "::View",
            ApplicationName   => $app_name,
            ApplicationUUID   => $app_uuid,
            LogLevel          => 'INFO',
            PubSub            => {
                Enable  => undef,
                Backend => 'Memcached',
            },
            Database => {
                AutoUpgrade     => 1,
                Database        => $db_name,
                Driver          => "SQLite",
                Host            => "localhost",
                Password        => "",
                User            => "",
                Version         => "0.0.1",
                RecordBaseClass => 'Jifty::DBI::Record::Cachable',
                CheckSchema     => '1'
            },
            Mailer     => 'Sendmail',
            MailerArgs => [],
            L10N       => { PoDir => "share/po", },

            View => {
                FallbackHandler => 'Jifty::View::Mason::Handler',
                Handlers => [
                    'Jifty::View::Static::Handler',
                    'Jifty::View::Declare::Handler',
                    'Jifty::View::Mason::Handler'
                ]
            },
            Web => {
                Port             => '8888',
                BaseURL          => 'http://localhost',
                DataDir          => "var/mason",
                StaticRoot       => "share/web/static",
                TemplateRoot     => "share/web/templates",
                ServeStaticFiles => 1,
                MasonConfig      => {
                    autoflush            => 0,
                    error_mode           => 'fatal',
                    error_format         => 'text',
                    default_escape_flags => 'h',
                },
                Globals => [],
            },
        },
    };

    # Make sure to handle any %path% values we may have guessed
    return $self->_expand_relative_paths($guess);
}


=head2 initial_config

Returns a default guessed config for a new application.

See L<Jifty::Script::App>.

=cut

sub initial_config {
    my $self = shift;
    my $guess = $self->guess(@_);
    $guess->{'framework'}->{'ConfigFileVersion'} = 2;

    # These are the plugins which new apps will get by default
    $guess->{'framework'}->{'Plugins'} = [
        { LetMe              => {}, },
        { SkeletonApp        => {}, },
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

    # This app configuration predates the plugin refactor
    if ( $config->{'framework'}->{'ConfigFileVersion'} < 2) {

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
                SessionCookieName => 'JIFTY_SID_$PORT',
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

    # Make sure %path% values are made absolute
    $hashref = $self->_expand_relative_paths($hashref);
    return $hashref;
}


# Does a DFS, turning all leaves that look like C<%paths%> into absolute paths.
sub _expand_relative_paths {
    my $self  = shift;
    my $datum = shift;

    # Recurse through each value in an array
    if ( ref $datum eq 'ARRAY' ) {
        return [ map { $self->_expand_relative_paths($_) } @$datum ];
    } 
    
    # Recurse through each value in a hash
    elsif ( ref $datum eq 'HASH' ) {
        for my $key ( keys %$datum ) {
            my $new_val = $self->_expand_relative_paths( $datum->{$key} );
            $datum->{$key} = $new_val;
        }
        return $datum;
    } 
    
    # Do nothing with other kinds of references
    elsif ( ref $datum ) {
        return $datum;
    } 
    
    # Check scalars for %path% and convert the enclosed value to an abspath
    else {
        if ( defined $datum and $datum =~ /^%(.+)%$/ ) {
            $datum = Jifty::Util->absolute_path($1);
        }
        return $datum;
    }
}

=head1 WHY SO MANY FILES

The Jifty configuration can be loaded from many locations. This breakdown allows for configuration files to be layered on top of each other for advanced deployments.

This section hopes to explain the intended purpose of each configuration file.

=head1 APPLICATION

The first configuration file loaded is the application configuration. This file provides the basis for the rest of the configuration loaded. The purpose of this file is for storing the primary application-specific configuration and defaults.

This can be used as the sole configuration file on a simple deployment. In a complex environment, however, this file may be considered read-only to be overridden by other files, allowing the later files to customize the configuration at each level.

=head1 VENDOR

The vendor configuration file is loaded and overrides settings in the application configuration. This is an intermediate level in the configuration. It overrides any defaults specified in the application configuration, but is itself overridden by the site configuration.

This provides an additional layer of abstraction for truly complicated deployments. A developer may provide a particular Jifty application (such as the Wifty wiki available from Best Practical Solutions) for download. A system administrator may have a standard set of configuration overrides to use on several different deployments that can be set using the vendor configuration, which can then be further overridden by each deployment using a site configuration. Several installations of the application might even share the vendor configuration file.

=head2 SITE

The site configuration allows for specific overrides of the application and vendor configuration. For example, a particular Jifty application might define all the application defaults in the application configuration file. Then, each administrator that has downloaded that appliation and is installing it locally might customize the configuration for a particular deployment using this configuration file, while leaving the application defaults intact (and, thus, still available for later reference). This can even override the vendor file containing a standard set of overrides.

=head1 SEE ALSO

L<Jifty>

=head1 AUTHOR

Various folks at BestPractical Solutions, LLC.

=head1 LICENSE

Jifty is Copyright 2005-2007 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
