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

use base qw/Class::Accessor/;
use Hook::LexWrap;
__PACKAGE__->mk_accessors(qw(mason dispatcher cgi apache));

=head2 new

Create a new Jifty::Handler object. Generally, Jifty.pm does this only once at startup.

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;

    $self->create_cache_directories();
    # Creating a new CGI object breaks FastCGI in all sorts of painful
    # ways.  So wrap the call and preempt it if we already have one
    use CGI;
    wrap 'CGI::new', pre => sub {
        $_[-1] = Jifty->handler->cgi if Jifty->handler->cgi;
    };


    $self->dispatcher(Jifty->config->framework('ApplicationClass')."::Dispatcher");
    Jifty::Util->require($self->dispatcher);
    return $self;
}


=head2 create_cache_directories

Attempts to create our app's session storage and mason cache directories.

=cut

sub create_cache_directories {
    my $self = shift;

    for ( Jifty->config->framework('Web')->{'SessionDir'},
          Jifty->config->framework('Web')->{'DataDir'}) {
        Jifty::Util->make_path( Jifty::Util->absolute_path($_) );
    }
}


=head2 mason_config

Returns our Mason config.  We use the component root specified in the
C<Web/TemplateRoot> framework configuration variable (or C<html> by
default).  Additionally, we set up a C<jifty> component root, as
specified by the C<Web/DefaultTemplateRoot> configuration.  All
interpolations are HTML-escaped by default, and we use the fatal error
mode.

=cut

sub mason_config {
    my %config = (
        static_source => 1,
        use_object_files => 1,
        data_dir =>  Jifty::Util->absolute_path( Jifty->config->framework('Web')->{'DataDir'} ),
        allow_globals => [qw[$JiftyWeb], @{Jifty->config->framework('Web')->{'Globals'} || []}],
        comp_root     => [ 
                          [application =>  Jifty::Util->absolute_path( Jifty->config->framework('Web')->{'TemplateRoot'} )],
                          [jifty => Jifty->config->framework('Web')->{'DefaultTemplateRoot'}],
                         ],
        %{ Jifty->config->framework('Web')->{'MasonConfig'} },
    );

    # In developer mode, we want halos, refreshing and all that other good stuff. 
    if (Jifty->config->framework('DevelMode') ) {
        push @{$config{'plugins'}}, 'Jifty::Mason::Halo';
            $config{static_source}        = 0;
            $config{use_object_files}        = 0;
            
            

    }
    return (%config);
        
}

=head2 cgi

Returns the L<CGI> object for the current request, or C<undef> if
there is none.

=head2 apache

Returns the L<HTML::Mason::FakeApache> or L<Apache> objecvt for the
current request, ot C<undef> if there is none.

=head2 handle_request

When your server processs (be it Jifty-internal, FastCGI or anything else) wants
to handle a request coming in from the outside world, you should call C<handle_request>.

=over

=item cgi

A L<CGI>.pm object that your server has already set up and loaded with your request's data

=back

=cut


sub handle_request {
    my $self = shift;
    my %args = (
        cgi           => undef,
        @_
    );

    Module::Refresh->refresh if (Jifty->config->framework('DevelMode') );
    $self->cgi($args{cgi});
    $self->apache(HTML::Mason::FakeApache->new(cgi => $self->cgi));

    local $HTML::Mason::Commands::JiftyWeb = Jifty::Web->new();
    Jifty->web->request(Jifty::Request->new()->fill($self->cgi));

    Jifty->web->response( Jifty::Response->new );
    Jifty->web->setup_session;
    Jifty->web->session->set_cookie;

    Jifty->log->debug("Received request for ".Jifty->web->request->path);

    # This should done in "new", but something is causing Jifty to handle 
    # one and only one session. after that, it gives us http headers but no content
    #
    $self->mason(Jifty::MasonHandler->new( $self->mason_config,));
    $self->dispatcher->handle_request();

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
    Jifty::Record->flush_cache;
    $self->cgi(undef);
    $self->apache(undef);
}

1;
