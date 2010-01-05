use strict;
use warnings;

package Jifty::Handler;

=head1 NAME

Jifty::Handler - Methods related to the finding and returning content

=head1 SYNOPSIS

  use Jifty;
  Jifty->new();

  my $handler = Jifty::Handler->handle_request( cgi => $cgi );

  # after each request is handled
  Jifty::Handler->cleanup_request;

=head1 DESCRIPTION

L<Jifty::Handler> provides methods required to find and return content
to the browser.  L</handle_request>, for instance, is the main entry
point for HTTP requests.

=cut

use base qw/Class::Accessor::Fast Jifty::Object/;
use Jifty::View::Declare::Handler ();
use Class::Trigger;
use String::BufferStack;

BEGIN {
    # Creating a new CGI object breaks FastCGI in all sorts of painful
    # ways.  So wrap the call and preempt it if we already have one
    use CGI ();

    # If this file gets reloaded using Module::Refresh, don't do this
    # magic again, or we'll get infinite recursion
    unless (CGI->can('__jifty_real_new')) {
        *CGI::__jifty_real_new = \&CGI::new;

        no warnings qw(redefine);
        *CGI::new = sub {
            return Jifty->handler->cgi if Jifty->handler->cgi;
            CGI::__jifty_real_new(@_);
        }
    }
};



__PACKAGE__->mk_accessors(qw(dispatcher _view_handlers cgi apache stash buffer));

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

=head2 cgi

Returns the L<CGI> object for the current request, or C<undef> if
there is none.

=head2 apache

Returns the L<HTML::Mason::FakeApache> or L<Apache> object for the
current request, ot C<undef> if there is none.

=head2 handle_request

When your server processs (be it Jifty-internal, FastCGI or anything
else) wants to handle a request coming in from the outside world, you
should call C<handle_request>.

=over

=item cgi

A L<CGI> object that your server has already set up and loaded with
your request's data.

=back

=cut


sub handle_request {
    my $self = shift;
    my %args = (
        cgi => undef,
        @_
    );

    $self->setup_view_handlers() unless $self->_view_handlers;

    $self->call_trigger('before_request', $args{cgi});

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

        $self->cgi( $args{cgi} );
        $self->apache( HTML::Mason::FakeApache->new( cgi => $self->cgi ) );

        Jifty->web->request( Jifty::Request->new()->fill( $self->cgi ) );
        Jifty->web->response( Jifty::Response->new );

        $self->call_trigger('have_request');

        Jifty->api->reset;
        for ( Jifty->plugins ) {
            $_->new_request;
        }
        $self->log->info( Jifty->web->request->request_method . " request for " . Jifty->web->request->path  );
        Jifty->web->setup_session;

        Jifty::I18N->get_language_handle;

        # Return from the continuation if need be
        unless (Jifty->web->request->return_from_continuation) {
            $self->buffer->out_method(\&Jifty::View::out_method);
            $self->dispatcher->handle_request();
        }

        $self->call_trigger('before_cleanup', $args{cgi});

        $self->cleanup_request();
    }

    $self->call_trigger('after_request', $args{cgi});
}

=head2 send_http_header

Sends any relevent HTTP headers, by calling
L<HTML::Mason::FakeApache/send_http_header>.  If this is running
inside a standalone server, also sends the HTTP status header first.

Returns false if the header has already been sent.

=cut

sub send_http_header {
    my $self = shift;
    return if $self->apache->http_header_sent;
    $Jifty::SERVER->send_http_status if $Jifty::SERVER;
    $self->apache->send_http_header;
    return 1;
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
    $self->cgi(undef);
    $self->apache(undef);
    $self->stash(undef);
    $self->buffer->pop for 1 .. $self->buffer->depth;
    $self->buffer->clear;
}

1;
