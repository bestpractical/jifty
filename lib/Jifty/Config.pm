use warnings;
use strict;

package Jifty::Config;

=head1 NAME

Jifty::Config - the configuration handler for Jifty

=head1 SYNOPSIS

    # in your application
    my $app_name = Jifty->config->framework('ApplicationName');
    my $frobber  = Jifty->config->app('PreferredFrobnicator');

    # sub classing
    package MyApp::Config;
    use base 'Jifty::Config';

    sub post_load {
        my $self = shift;
        my $stash = $self->stash; # full config in a hash

        ... do something with options ...

        $self->stash( $stash ); # save config
    }

    1;

=head1 DESCRIPTION

This class is automatically loaded during Jifty startup. It contains the configuration information loaded from the F<config.yml> file (generally stored in the F<etc> directory of your application, but see L</load> for the details). This configuration file is stored in L<YAML> format.

This configuration file contains two major sections named "framework" and "application". The framework section contains Jifty-specific configuration options and the application section contains whatever configuration options you want to use with your application. (I.e., if there's any configuration information your application needs to know at startup, this is a good place to put it.)

Usually you don't need to know anything about this class except
L<app|/"app VARIABLE"> and L<framework|/"framework VARIABLE"> methods and
about various config files and order in which they are loaded what
described in L</load>.

=cut

use Jifty::Util;
use Jifty::YAML;

use Hash::Merge;
Hash::Merge::set_behavior('RIGHT_PRECEDENT');

use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(qw/stash/);

use vars qw/$CONFIG/;

=head1 ACCESSING CONFIG

=head2 framework VARIABLE

Get the framework configuration variable C<VARIABLE>.

    Jifty->config->framework('ApplicationName')

=cut

sub framework { return shift->_get( framework => @_ ) }

=head2 app VARIABLE

Get the application configuration variable C<VARIABLE>.

    Jifty->config->framework('MyOption');

=cut

sub app { return shift->_get( application => @_ ) }

# A teeny helper for framework and app
sub _get { return $_[0]->stash->{ $_[1] }{ $_[2] } }

=head2 contextual_get CONTEXT VARIABLE

Gets the configuration variable in the context C<CONTEXT>. The C<CONTEXT> is a
slash-separated list of hash keys. For example, the following might return
C<SQLite>:

    contextual_get('/framework/Database', 'Driver')

=cut

sub contextual_get {
    my $self    = shift;
    my $context = shift;
    my $field   = shift;

    my $pointer = $self->stash;

    my @fragments = grep { length } split '/', $context;
    for my $fragment (@fragments) {
        $pointer = $pointer->{$fragment} || return;
    }

    return $pointer->{$field};
}

=head1 LOADING

=head2 new PARAMHASH

In general, you never need to call this, just use:

  Jifty->config

in your application.

This class method instantiates a new C<Jifty::Config> object.

PARAMHASH currently takes a single option

=over

=item load_config

This boolean defaults to true. If true, L</load> will be called upon
initialization. Using this object without loading prevents sub-classing
and only makes sense if you want to generate default config for
a new jifty application or something like that.

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

Loads all config files for your application and initializes application
level sub-class.

Called from L<new|/"new PARAMHASH">, takes no arguments,
returns nothing interesting, but do the following:

=head3 Application config

Jifty first loads the main configuration file for the application, looking for
the C<JIFTY_CONFIG> environment variable or C<etc/config.yml> under the
application's base directory.

=head3 Vendor config

It uses the main configuration file to find a vendor configuration
file -- if it doesn't find a framework variable named 'VendorConfig',
it will use the C<JIFTY_VENDOR_CONFIG> environment variable.

=head3 Site config

After loading the vendor configuration file (if it exists), the
framework will look for a site configuration file, specified in either
the framework's C<SiteConfig> or the C<JIFTY_SITE_CONFIG> environment
variable. (Usually in C<etc/site_config.yml>.)

=head3 Test config(s)

After loading the site configuration file (if it exists), the
framework will look for a test configuration file, specified in either
the framework's C<TestConfig> or the C<JIFTY_TEST_CONFIG> environment
variable.

Note that the test config may be drawn from several files if you use
L<Jifty::Test>. See the documentation of L<Jifty::Test::load_test_configs>.

=head3 Options clobbering

Values in the test configuration will clobber the site configuration.
Values in the site configuration file clobber those in the vendor
configuration file. Values in the vendor configuration file clobber
those in the application configuration file.
(See L</WHY SO MANY FILES> for a deeper search for truth on this matter.)

=head3 Guess defaults

Once we're all done loading from files, several defaults are
assumed based on the name of the application -- see L</guess>.

=head3 Reblessing into application's sub-class

OK, config is ready. Rebless this object into C<YourApp::Config> class
and call L</post_load> hook, so you can do some tricks detailed in
L</SUB-CLASSING>.

=head3 Another hook

After we have the config file, we call the coderef in C<$Jifty::Config::postload>,
if it exists. This last bit is generally used by the test harness to do
a little extra work.

=head3 B<SPECIAL PER-VALUE PROCESSING>

If a value begins and ends with "%" (e.g., "%bin/foo%"), converts it with
C<Jifty::Util/absolute_path> to an absolute path. This is typically
unnecessary, but helpful for configuration variables such as C<MailerArgs>
that only sometimes specify files.

=cut

sub load {
    my $self = shift;

    # Add the default configuration file locations to the stash
    $self->merge( $self->_default_config_files );

    # Calculate the location of the application etc/config.yml
    my $file = $ENV{'JIFTY_CONFIG'} || Jifty::Util->app_root . '/etc/config.yml';

    my $app;

    # Start by loading application configuration file
    if ( -f $file and -r $file ) {
        # Load the $app so we know where to find the vendor config file
        $self->merge( $self->load_file($file) );
    }

    # Load the vendor configuration file
    my $vendor = $self->load_file(
        Jifty::Util->absolute_path(
            $self->framework('VendorConfig') || $ENV{'JIFTY_VENDOR_CONFIG'}
        )
    );

    # Merge the app config with vendor config, vendor taking precedent
    $self->merge( $vendor );

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
    $self->merge( $site );

    # Load the test configuration file
    my $test = $self->load_file(
        Jifty::Util->absolute_path(
            $self->framework('TestConfig') || $ENV{'JIFTY_TEST_CONFIG'}
        )
    );

    # Merge the app, vendor, site and test config, test taking precedent
    $self->merge( $test );

    # Merge guessed values in for anything we didn't explicitly define
    # Whatever's in the stash overrides anything we guess
    $self->merge( $self->stash, $self->guess );
    
    # There are a couple things we want to guess that we don't want
    # getting stuck in a default config file for an app
    $self->merge( $self->stash, $self->defaults );

    # Bring old configurations up to current expectations
    $self->stash($self->update_config($self->stash));

    # check for YourApp::Config
    my $app_class = $self->framework('ApplicationClass') . '::Config';
    # we have no class loader at this moment :(
    my $found = Jifty::Util->try_to_require( $app_class );
    if ( $found && $app_class->isa('Jifty::Config') ) {
        bless $self, $app_class;
    } elsif ( $found ) {
# XXX this warning is not always useful, sometimes annoying, 
# e.g. RT has its own config mechanism, we don't want to sub-class
# Jifty::Config at all.
#        warn "You have $app_class, however it's not an sub-class of Jifty::Config."
#            ." Read `perldoc Jifty::Config` about subclassing. Skipping.";
    }

    # post load hook for sub-classes
    $self->post_load;

    # Finally, check for global postload hooks (these are used by the
    # test harness)
    $self->$Jifty::Config::postload()
      if $Jifty::Config::postload;
}

=head2 merge NEW, [FALLBACK]

Merges the given C<NEW> hashref into the stash, with values taking
precedence over pre-existing ones from C<FALLBACK>, which defaults to
L</stash>.  This also deals with special cases (MailerArgs,
Handlers.View) where array reference contents should be replaced, not
concatenated.

=cut

sub merge {
    my $self = shift;
    my ($new, $fallback) = @_;
    $fallback ||= $self->stash;

    # These are now more correctly done with the ! syntax, below, rather
    # than these special-cases.
    delete $fallback->{framework}{MailerArgs} if exists $new->{framework}{MailerArgs};
    delete $fallback->{framework}{View}{Handlers} if exists $new->{framework}{View}{Handlers};

    my $unbang;
    $unbang = sub {
        my $ref = shift;
        if (ref $ref eq "HASH") {
            $ref->{$_} = delete $ref->{$_ . "!"}
                for map {s/!$//; $_} grep {/!$/} keys %{$ref};
            $ref->{$_} = $unbang->( $ref->{$_} )
                for keys %{$ref};
        } elsif (ref $ref eq "ARRAY") {
            $ref = [ map { $unbang->($_) } @{$ref} ];
        }
        return $ref;
    };

    $self->stash( $unbang->( Hash::Merge::merge( $fallback, $new ) ) );
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

=head2 post_load

Helper hook for L</SUB-CLASSING> and post processing config. At this
point does nothing by default. That may be changed so do something like:

    sub post_load {
        my $self = shift;
        $self->post_load( @_ );
        ...
    }

=cut

sub post_load {}

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

=head1 OTHER METHODS

=head2 stash

It's documented only for L</SUB-CLASSING>.

Returns the current config as a hash reference (see below). Plenty of code
considers Jifty's config as a static thing, so B<don't mess> with it in
run-time.

    {
        framework => {
            ...
        },
        application => {
            ...
        },
    }

This method as well can be used to set a new config:

    $config->stash( $new_stash );

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
                PSGIStatic => 1,
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
    $guess->{'framework'}->{'ConfigFileVersion'} = 6;

    # These are the plugins which new apps will get by default
    $guess->{'framework'}->{'Plugins'} = [
        { AdminUI            => {}, },
        { CompressedCSSandJS => {}, },
        { ErrorTemplates     => {}, },
        { Halo               => {}, },
        { LetMe              => {}, },
        { OnlineDocs         => {}, },
        { REST               => {}, },
        { SkeletonApp        => {}, },
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
            { AdminUI            => {}, },
            { CompressedCSSandJS => {}, },
            { ErrorTemplates     => {}, },
            { Halo               => {}, },
            { OnlineDocs         => {}, },
            { REST               => {}, },
            { SkeletonApp        => {}, },
        );
    }

    if ( $config->{'framework'}->{'ConfigFileVersion'} < 3) {
        unshift (@{$config->{'framework'}->{'Plugins'}}, 
            { CSSQuery           => {}, }
        );
    }

    if ( $config->{'framework'}->{'ConfigFileVersion'} < 4) {
        unshift (@{$config->{'framework'}->{'Plugins'}}, 
            { Prototypism        => {}, }
        );
    }

    if ( $config->{'framework'}->{'ConfigFileVersion'} < 5) {
        unshift (@{$config->{'framework'}->{'Plugins'}},
            { Compat        => {}, }
        );

        push (@{$config->{'framework'}->{'Plugins'}},
            { Deflater      => {}, }
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

=head1 SUB-CLASSING

Template for sub-classing you can find in L</SYNOPSIS>.

Application config may have ApplicationClass or ApplicationName options,
so it's B<important> to understand that your class goes into game later.
Read </load> to understand when C<YourApp::Config> class is loaded.

Use L</stash> method to get and/or change config.

L</post_load> hook usually is all you want to (can :) ) sub class. Other
methods most probably called before your class can operate.

Sub-classing may be useful for:

=over 4

=item * validation

For example check if file or module exists.

=item * canonicalization

For example turn relative paths into absolute or translate all possible
variants of an option into a canonical structure

=item * generation

For example generate often used constructions based on other options,
user of your app can even don't know about them

=item * config upgrades

Jifty has ConfigVersion option you may want to implement something like
that in your apps

=back

Sub-classing is definitely not for:

=over 4

=item * default values

You have L<so many files|/"WHY SO MANY FILES"> to allow users of your
app and you to override defaults.

=item * anything else but configuration

=back

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

The site configuration allows for specific overrides of the application and vendor configuration. For example, a particular Jifty application might define all the application defaults in the application configuration file. Then, each administrator that has downloaded that application and is installing it locally might customize the configuration for a particular deployment using this configuration file, while leaving the application defaults intact (and, thus, still available for later reference). This can even override the vendor file containing a standard set of overrides.

=head1 MERGING RULES

Values from files loaded later take precedence; that is, Jifty's
defaults are overridden by the application configuration file, then the
vendor configuration file, then the site configuration file.  At each
step, the new values are merged into the old values using
L<Hash::Merge>.  Specifically, arrays which exist in both old and new
data structures are appended, and hashes are merged.

One special rule applies, however: if a key in a hash ends in C<!>, the
it simply overrides the equivalent non-C<!> key's value, ignoring normal
merging rules.

=head1 SEE ALSO

L<Jifty>

=head1 AUTHOR

Various folks at BestPractical Solutions, LLC.

=head1 LICENSE

Jifty is Copyright 2005-2010 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
