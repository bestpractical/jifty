use warnings;
use strict;

package Jifty;
use IPC::PubSub 0.22;
use Data::UUID;
use encoding 'utf8';
use Class::Trigger;

BEGIN {
    # Work around the fact that Time::Local caches TZ on first require
    local $ENV{'TZ'} = "GMT";
    require Time::Local;

    # Declare early to make sure Jifty::Record::schema_version works
    $Jifty::VERSION = '1.11108';
}

=head1 NAME

Jifty - an application framework

=head1 SYNOPSIS

 # Object containing lots of web related goodies...
 my $web      = Jifty->web;
 my $request  = Jifty->web->request;
 my $response = Jifty->web->response;
 my $link     = Jifty->web->link( label => _('W00t'), url => '/whatsit' );

 # Retrieve information from your application's etc/config.yml file.
 my $config   = Jifty->config;

 # Retrieve the Jifty::DBI handle
 my $handle   = Jifty->handle;

 # Load an application class, very handy in plugins
 my $class    = Jifty->app_class('Model', 'Foo');
 my $foo      = $class->new;
 $foo->create( frobnicate => 42 );

 # Configure information related to your application's actions
 my $api      = Jifty->api;

 # Make parts of your page "subscribe" to information in a fragment
 my $subs     = Jifty->subs;

 # Share information via IPC::PubSub in your application
 my $bus      = Jifty->bus;

 # Retrieve general information about Mason
 my $handler  = Jifty->handler;

=head1 DESCRIPTION

Yet another web framework.

=head2 What's cool about Jifty? (Buzzwords)

=over 4

=item DRY (Don't Repeat Yourself)

Jifty tries not to make you say things more than once.

=item Full-stack

Out of the proverbial box, Jifty comes with one way to do everything
you should need to do: One database mapper, one templating system, one
web services layer, one AJAX toolkit, one set of handlers for
standalone or FastCGI servers. We work hard to make all the bits play
well together, so you don't have to.

=item Continuations

With Jifty, it's easy to let the user go off and do something else,
like fill out a wizard, look something up in the help system or go
twiddle their preferences and come right back to where they were.

=item Form-based dispatch

This is one of the things that Jifty does that we've not seen anywhere
else. Jifty owns your form rendering and processing. This means you
never need to write form handling logic. All you say is "I want an
input for this argument here" and Jifty takes care of the rest. (Even
autocomplete and validation)

=item A Pony

Jifty is the only web application framework that comes with a pony.

=back

=head2 Introduction

If this is your first time using Jifty, L<Jifty::Manual::Tutorial> is
probably a better place to start.

=cut


use base qw/Jifty::Object/;
use Jifty::Everything;

use vars qw/$HANDLE $CONFIG $LOGGER $HANDLER $API $CLASS_LOADER $PUB_SUB $WEB @PLUGINS/;

=head1 METHODS

=head2 new PARAMHASH

This class method instantiates a new C<Jifty> object. This object
deals with configuration files, logging and database handles for the
system.  Before this method returns, it calls the application's C<start>
method (i.e. C<MyApp-E<gt>start>) to handle any application-specific startup.

Most of the time, the server will call this for you to set up
your C<Jifty> object.  If you are writing command-line programs that
want to use your libraries (as opposed to web services) you will need
to call this yourself.

See L<Jifty::Config> for details on how to configure your Jifty
application.

=head3 Arguments

=over

=item no_handle

If this is set to true, Jifty will not create a L<Jifty::Handle> and
connect to a database.  Only use this if you're about to drop the
database or do something extreme like that; most of Jifty expects the
handle to exist.  Defaults to false.

=item logger_component

The name that Jifty::Logger will log under.  If you don't specify anything
Jifty::Logger will log under the empty string.  See L<Jifty::Logger> for
more information.

=back

=cut

sub new {
    my $ignored_class = shift;

    # Setup the defaults
    my %args = (
        no_handle        => 0,
        no_request       => 0,
        pre_init         => 0,
        logger_component => undef,
        @_
    );

    # Add the application's library path
    push @INC, File::Spec->catdir(Jifty::Util->app_root, "lib");

    # Now that we've loaded the configuration, we can remove the temporary 
    # Jifty::DBI::Record baseclass for records and insert our "real" baseclass,
    # which is likely Record::Cachable or Record::Memcached
    @Jifty::Record::ISA = grep { $_ ne 'Jifty::DBI::Record' } @Jifty::Record::ISA;

    # Configure the base class used by Jifty models
    my $record_base_class = Jifty->config->framework('Database')->{'RecordBaseClass'};
    Jifty::Util->require( $record_base_class );
    push @Jifty::Record::ISA, $record_base_class unless $record_base_class eq 'Jifty::Record';

    # Configure the base class for Jifty::CAS
    Jifty::CAS->setup;

    # Logger turn on
    Jifty->logger( Jifty::Logger->new( $args{'logger_component'} ) );

    # Set up plugins
    my @plugins;
    my @plugins_to_load = @{Jifty->config->framework('Plugins')};
    my $app_plugin = Jifty->app_class('Plugin');
    # we are pushing prereq to plugin, hence the 3-part for.
    for (my $i = 0; my $plugin = $plugins_to_load[$i]; $i++) {
        my $is_prereq = delete $plugin->{_prereq};

        # Prepare to learn the plugin class name
        my ($plugin_name) = keys %{$plugin};
        my $class;

        # Is the plugin name a fully-qualified class name?
        if ($plugin_name =~ /^(?:Jifty::Plugin|$app_plugin)::/) {
            # app-specific plugins use fully qualified names, Jifty plugins may
            $class = $plugin_name; 
        }

        # otherwise, assume it's a short name, qualify it
        else {
            $class = "Jifty::Plugin::".$plugin_name;
        }

        # avoid duplicating prereq plugins. we can't do this in the loop below
        # because a plugin might prereq a plugin later in config.yml
        if ($is_prereq) {
            my $this_class = qr/^(?:Jifty::Plugin::|\Q$app_plugin\E)?\Q$plugin_name\E$/;

            next if grep { $_ =~ $this_class } @plugins_to_load;

            # already loaded plugin objects
            next if grep { ref($_) =~ $this_class } @plugins;
        }

        # Load the plugin options
        my %options = (%{ $plugin->{ $plugin_name } },
                        _pre_init => $args{'pre_init'} );

        # Load the plugin code
        Jifty::Util->require($class);
        Jifty::ClassLoader->new(base => $class)->require;

        # Initialize the plugin and mark the prerequisites for loading too
        my $plugin_obj = $class->new(%options);
        push @plugins, $plugin_obj;
        foreach my $name ($plugin_obj->prereq_plugins) {
            push @plugins_to_load, {$name => {}, _prereq => 1};
        }
    }

    # All plugins loaded, save them for later reference
    Jifty->plugins(@plugins);

    # Now that we have the config set up and loaded plugins,
    # load the localization files.
    Jifty::I18N->refresh();
    
    # Get a classloader set up
    my $class_loader = Jifty::ClassLoader->new(
        base => Jifty->app_class,
    );

    # Save the class loader for later reference
    Jifty->class_loader($class_loader);
    $class_loader->require;

    # Configure the request handler and action API handler
    Jifty->handler(Jifty::Handler->new()) unless Jifty->handler;
    Jifty->api(Jifty::API->new()) unless Jifty->api;

    # We can only require view classes once we have our models and actions set.
    $class_loader->require_views;

    # Let's get the database rocking and rolling
    Jifty->setup_database_connection(%args);

    # Call the application's start method to let it do anything
    # application specific for startup
    my $app = Jifty->app_class;
    
    # Run the App::start() method if it exists for app-specific initialization
    $app->start
        if not $args{no_handle} and $app->can('start');

    # Setup an empty request and response if we're not in a web environment
    if ($args{no_request}) {
        Jifty->web->request(Jifty::Request->new);
        Jifty->web->response(Jifty::Response->new);
    }

    # For plugins that want all the above initialization, but want to run before
    # we begin serving requests
    Jifty->call_trigger('post_init');
}

# Explicitly destroy the classloader; if this happens during global
# destruction, there's a period of time where there's a bogus entry in
# @INC
END {
    Jifty->class_loader->DESTROY if Jifty->class_loader;
}

=head2 config

An accessor for the L<Jifty::Config> object that stores the
configuration for the Jifty application.

=cut

sub config {
    my $class = shift;
    $CONFIG = shift if (@_);
    $CONFIG ||= Jifty::Config->new();
    return $CONFIG;
}

=head2 logger

An accessor for our L<Jifty::Logger> object for the application.

You probably aren't interested in this. See L</log> for information on how to
make log messages.

=cut

sub logger {
    my $class = shift;
    $LOGGER = shift if (@_);
    return $LOGGER;
}

=head2 handler

An accessor for our L<Jifty::Handler> object.

This is another method that you usually don't want to mess with too much.
Most of the interesting web bits are handled by L</web>.

=cut

sub handler {
    my $class = shift;
    $HANDLER = shift if (@_);
    return $HANDLER;
}

=head2 handle

An accessor for the L<Jifty::Handle> object that stores the database
handle for the application.

=cut

sub handle {
    my $class = shift;
    $HANDLE = shift if (@_);
    return $HANDLE;
}

=head2 api

An accessor for the L<Jifty::API> object that publishes and controls
information about the application's L<Jifty::Action>s.

=cut

sub api {
    my $class = shift;
    $API = shift if (@_);
    return $API;
}

=head2 app_class(@names)

Return Class in application space.  For example C<app_class('Model', 'Foo')>
returns YourApp::Model::Foo.

By the time you get it back, the class will have already been required

Is you pass a hashref as the first argument, it will be treated as
configuration parameters.  The only existing parameter is C<require>,
which defaults to true.

=cut

sub app_class {
    shift;
    my $args = (ref $_[0] ? shift : { require => 1 });
    my $val = join('::', Jifty->config->framework('ApplicationClass'), @_);
    Jifty::Util->try_to_require($val) if $args->{require};
    return $val;
}

=head2 web

An accessor for the L<Jifty::Web> object that the web interface uses. 

=cut

sub web {
    return $Jifty::WEB ||= Jifty::Web->new();
}

=head2 subs

An accessor for the L<Jifty::Subs> object that the subscription uses. 

=cut

sub subs {
    return Jifty::Subs->new;
}

=head2 bus

Returns an IPC::PubSub object for the current application.

=cut

sub bus {
    my $class = shift;
    my %args = ( connect => 1, @_ );
    if (not $PUB_SUB and $args{connect}) {
        my @args;

        my $backend = Jifty->config->framework('PubSub')->{'Backend'};
        if ( $backend eq 'Memcached' ) {
            require IO::Socket::INET;

            # If there's a running memcached on the default port. this should become configurable
            if ( IO::Socket::INET->new('127.0.0.1:11211') ) {
                @args = ( Jifty->app_instance_id );
            } else {
                $backend = 'JiftyDBI';
            }
        } 
        
        if ($backend eq 'JiftyDBI' and Jifty->handle ) {
                @args    = (
                    db_config    => Jifty->handle->{db_config},
                    table_prefix => '_jifty_pubsub_',
                );
            }
        $PUB_SUB = IPC::PubSub->new( $backend => @args );

    }
    return $PUB_SUB;
}

=head2 plugins

Returns a list of L<Jifty::Plugin> objects for this Jifty application.

=cut

sub plugins {
    my $class = shift;
    @PLUGINS = @_ if @_;
    return @PLUGINS;
}

=head2 find_plugin

Find plugins by name.

=cut

sub find_plugin {
    my $self = shift;
    my $name = shift;

    my @plugins = grep { $_->isa($name) } Jifty->plugins;
    return wantarray ? @plugins : $plugins[0];
}

=head2 class_loader

An accessor for the L<Jifty::ClassLoader> object that stores the loaded
classes for the application.

=cut

sub class_loader {
    my $class = shift;
    $CLASS_LOADER = shift if (@_);
    return $CLASS_LOADER;
}

=head2 setup_database_connection

Set up our database connection. Optionally takes a paramhash with a
single argument.  This method is automatically called by L</new>.

=over

=item no_handle

Defaults to false. If true, Jifty won't try to set up a database handle

=item pre_init

Defaults to false. If true, plugins are notified that this is a
pre-init, any trigger registration in C<init()> should not happen
during this stage.  Note that model mixins' C<register_triggers> is
unrelated to this.

=back


If C<no_handle> is set or our application's config file is missing a C<Database> configuration
 section or I<has> a C<SkipDatabase: 1> directive in its framework configuration, does nothing.

=cut

sub setup_database_connection {
    my $self = shift;
    my %args = (no_handle  => 0,
                check_opts => {},
                @_);

    # Don't setup the database connection if we're told not to
    unless ( $args{'no_handle'}
        or Jifty->config->framework('SkipDatabase')
        or not Jifty->config->framework('Database') )
    {

        # Load the application's database handle and connect
        my $handle_class = Jifty->app_class("Handle");
        Jifty::Util->require( $handle_class );
        Jifty->handle( $handle_class->new );
        Jifty->handle->connect();

        # Clean out any stale Cache::Memcached connections
        $Jifty::DBI::Record::Memcached::MEMCACHED->disconnect_all
            if $Jifty::DBI::Record::Memcached::MEMCACHED;

        # Make sure the app version matches the database version
        Jifty->handle->check_schema_version(%{$args{'check_opts'}})
            unless $args{'no_version_check'};
    }
}


=head2 app_instance_id

Returns a globally unique id for this instance of this jifty 
application. This value is generated the first time it's accessed

=cut

sub app_instance_id {
    my $self = shift;
    my $app_instance_id = Jifty::Model::Metadata->load("application_instance_uuid");
    unless ($app_instance_id) {
        require Data::UUID;
        $app_instance_id = Data::UUID->new->create_str();
        Jifty::Model::Metadata->store(application_instance_uuid => $app_instance_id );
    }
    return $app_instance_id;
}

=head2 background SUB

Forks a background process, and ensures that database connections and
sockets are not shared with the parent process.

=cut

sub background {
    my $class = shift;
    my $sub = shift;
    if (my $pid = fork) {
        return $pid;
    } else {
        close STDOUT;
        close STDIN;
        # XXX: make $Jifty::SERVER close client sockets if exists
        Jifty->handle->dbh->{InactiveDestroy} = 1;
        Jifty->setup_database_connection();
        $sub->();
        exit;
    }
}

=head2 admin_mode

Returns true if the application is in admin mode. This should be used instead
of C<< Jifty->config->framework('AdminMode') >>.

=cut

sub admin_mode {
    return Jifty->config->framework('AdminMode')
        || Jifty->config->framework('SetupMode');
}

=head1 SEE ALSO

L<http://jifty.org>, L<Jifty::Manual::Tutorial>, L<Jifty::Everything>, L<Jifty::Config>, L<Jifty::Handle>, L<Jifty::Logger>, L<Jifty::Handler>, L<Jifty::Web>, L<Jifty::API>, L<Jifty::Subs>, L<IPC::PubSub>, L<Jifty::Plugin>, L<Jifty::ClassLoader>

=head1 AUTHORS

Jesse Vincent, Alex Vandiver and David Glasser.

=head1 LICENSE

Jifty is Copyright 2005-2010 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.



=cut

1;
