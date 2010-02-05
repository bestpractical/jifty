use strict;
use warnings;

package Jifty::Handler;

=head1 NAME

Jifty::Handler - Methods related to the finding and returning content

=head1 SYNOPSIS

  use Jifty;
  Jifty->new();

  my $handler = Jifty::Handler->new;
  $handler->handle_request( $env );

=head1 DESCRIPTION

L<Jifty::Handler> provides methods required to find and return content
to the browser.  L</handle_request>, for instance, is the main entry
point for HTTP requests.

=cut

use base qw/Class::Accessor::Fast Jifty::Object/;
use Jifty::View::Declare::Handler ();
use Class::Trigger;
use String::BufferStack;
use Plack::Request;
use Plack::Builder;
use Plack::Util;

__PACKAGE__->mk_accessors(qw(dispatcher _view_handlers stash buffer));

=head2 new

Create a new Jifty::Handler object. Generally, Jifty.pm does this only once at startup.

=cut

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    $self->dispatcher( Jifty->app_class( "Dispatcher" ) );
    Jifty::Util->require( $self->dispatcher );
    $self->dispatcher->import_plugins;
    eval { Jifty::Plugin::DumpDispatcher->dump_rules };

    $self->buffer(String::BufferStack->new( out_method => \&Jifty::View::out_method ));
    {
        my $buffer = $self->buffer;
        no warnings 'redefine';
        *Jifty::Web::out = sub {shift;unshift @_,$buffer;goto \&String::BufferStack::append};
    }
    return $self;
}


=head2 view_handlers

Returns a list of modules implementing view for your Jifty application.

You can override this by specifying: 

  framework:
      View:
         Handlers:
            - Jifty::View::Something::Handler
            - Jifty::View::SomethingElse::Handler


=cut

sub view_handlers {
    my @default = @{Jifty->config->framework('View')->{'Handlers'}};

    # If there's a (deprecated) fallback handler, and it's not already
    # in our set of handlers, tack it on the end
    my $fallback = Jifty->config->framework('View')->{'FallbackHandler'};
    push @default, $fallback if defined $fallback and not grep {$_ eq $fallback} @default;

    return @default;
}


=head2 setup_view_handlers

Initialize all of our view handlers. 

=cut

sub setup_view_handlers {
    my $self = shift;

    $self->_view_handlers({});
    foreach my $class ($self->view_handlers()) {
        $self->_view_handlers->{$class} =  $class->new();
    }
}

=head2 view ClassName

Returns the Jifty view handler for C<ClassName>.

=cut

sub view {
    my $self = shift;
    my $class = shift;
    $self->setup_view_handlers unless $self->_view_handlers;
    return $self->_view_handlers->{$class};
}

=head2 psgi_app

Returns a closure for L<PSGI> application.

=cut

sub psgi_app {
    my $self = shift;

    my $app = sub { $self->handle_request(@_) };

    # allow plugin to wrap $app
    builder {
        enable 'Deflater';
        enable sub { my $app = shift;
                     sub { my $env = shift;
                           my $res = $app->($env);
                           my $h = Plack::Util::headers($res->[1]);
                           my $type = $h->get('Content-Type')
                               or return $res;
                           delete $env->{HTTP_ACCEPT_ENCODING}
                               unless $type =~ m|application/x-javascript| || $type =~ m|^text/|;
                           $res }
                 };
        $app;
    };
}

=head2 handle_request

When your server processs (be it Jifty-internal, FastCGI or anything
else) wants to handle a request coming in from the outside world, you
should call C<handle_request>.

=cut

sub handle_request {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);
    my $response;

    $self->setup_view_handlers() unless $self->_view_handlers;

    $self->call_trigger('before_request', $req);

    # this is scoped deeper because we want to make sure everything is cleaned
    # up for the LeakDetector plugin. I tried putting the triggers in the
    # method (Jifty::Server::handle_request) that calls this, but Jifty::Server
    # isn't being loaded in time
    {
        # Build a new stash for the life of this request
        $self->stash( {} );
        local $Jifty::WEB = Jifty::Web->new();

        if ( Jifty->config->framework('DevelMode') ) {
            require Module::Refresh;
            Module::Refresh->refresh;
            Jifty::I18N->refresh;
        }

        Jifty->web->request( Jifty::Request->promote( $req ) );
        Jifty->web->response( Jifty::Response->new );
        Jifty->web->response->status(200);

        $self->call_trigger('have_request');

        Jifty->api->reset;
        for ( Jifty->plugins ) {
            $_->new_request;
        }
        $self->log->info( Jifty->web->request->method . " request for " . Jifty->web->request->path  );
        Jifty->web->setup_session;

        Jifty::I18N->get_language_handle;

        # Return from the continuation if need be
        unless (Jifty->web->request->return_from_continuation) {
            $self->buffer->out_method(\&Jifty::View::out_method);
            $self->dispatcher->handle_request();
        }

        $self->call_trigger('before_cleanup', $req);

        $self->cleanup_request();
        $response = Jifty->web->response;
    }

    $self->call_trigger('after_request', $req);
    return $response->finalize;
}

=head2 cleanup_request

Dispatchers should call this at the end of each request, as a class method.
It flushes the session to disk, as well as flushing L<Jifty::DBI>'s cache. 

=cut

sub cleanup_request {
    my $self = shift;

    # Clean out the cache. the performance impact should be marginal.
    # Consistency is improved, too.

    Jifty->web->session->unload();
    Jifty::Record->flush_cache if Jifty::Record->can('flush_cache');
    $self->stash(undef);
    $self->buffer->pop for 1 .. $self->buffer->depth;
    $self->buffer->clear;
}

1;
