use strict;
use warnings;

package Jifty::Handler;

=head1 NAME

Jifty::Handler - Methods related to the Mason handler

=head1 SYNOPSIS

  use Jifty;
  Jifty->new();

  my $handler = Jifty::Handler->handle_request( cgi => $cgi );

  # after each request is handled
  Jifty::Handler->cleanup_request;

=head1 DESCRIPTION

L<Jifty::Handler> provides methods required to deal with Mason CGI
handlers.  

=cut

use base qw/Class::Accessor::Fast/;
use Module::Refresh ();
use Jifty::View::Declare::Handler ();

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



__PACKAGE__->mk_accessors(qw(mason dispatcher declare_handler static_handler cgi apache stash));

=head2 new

Create a new Jifty::Handler object. Generally, Jifty.pm does this only once at startup.

=cut

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    $self->create_cache_directories();

    $self->dispatcher( Jifty->app_class( "Dispatcher" ) );
    Jifty::Util->require( $self->dispatcher );
    $self->dispatcher->import_plugins;
	eval { Jifty::Plugin::DumpDispatcher->dump_rules };

    $self->setup_view_handlers();
    return $self;
}

sub _template_handlers { qw(declare_handler mason) }
sub _fallback_template_handler { 'mason' }

=head2 setup_view_handlers

Initialize all of our view handlers. 

XXX TODO: this should take pluggable views

=cut

sub setup_view_handlers {
    my $self = shift;

    $self->declare_handler( Jifty::View::Declare::Handler->new());
    $self->mason( Jifty::View::Mason::Handler->new());
    $self->static_handler(Jifty::View::Static::Handler->new());
}


=head2 create_cache_directories

Attempts to create our app's mason cache directory.

=cut

sub create_cache_directories {
    my $self = shift;

    for ( Jifty->config->framework('Web')->{'DataDir'} ) {
        Jifty::Util->make_path( Jifty::Util->absolute_path($_) );
    }
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

    if ( Jifty->config->framework('DevelMode') ) {
        Module::Refresh->refresh;
        Jifty::I18N->refresh;
    }

    Jifty::I18N->get_language_handle;

    $self->cgi( $args{cgi} );
    $self->apache( HTML::Mason::FakeApache->new( cgi => $self->cgi ) );

    # Build a new stash for the life of this request
    $self->stash({});
    local $HTML::Mason::Commands::JiftyWeb = Jifty::Web->new();

    Jifty->web->request( Jifty::Request->new()->fill( $self->cgi ) );
    Jifty->web->response( Jifty::Response->new );
    Jifty->api->reset;
    $_->new_request for Jifty->plugins;

    Jifty->log->debug( "Received request for " . Jifty->web->request->path );
    my $sent_response = 0;
    $sent_response
        = $self->static_handler->handle_request( Jifty->web->request->path )
        if ( Jifty->config->framework('Web')->{'ServeStaticFiles'} );

    Jifty->web->setup_session unless $sent_response;

    # Return from the continuation if need be
    Jifty->web->request->return_from_continuation;

    unless ($sent_response) {
        Jifty->web->session->set_cookie;
        $self->dispatcher->handle_request()
    }

    $self->cleanup_request();

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
}

1;
