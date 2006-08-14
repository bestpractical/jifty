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



__PACKAGE__->mk_accessors(qw(mason dispatcher static_handler cgi apache stash));

=head2 new

Create a new Jifty::Handler object. Generally, Jifty.pm does this only once at startup.

=cut

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    $self->create_cache_directories();
#    wrap 'CGI::new', pre => sub {
#        $_[-1] = Jifty->handler->cgi if Jifty->handler->cgi;
#    };

    $self->dispatcher(
        Jifty->config->framework('ApplicationClass') . "::Dispatcher" );
    Jifty::Util->require( $self->dispatcher );
    $self->dispatcher->import_plugins;
    $self->dispatcher->dump_rules;

    $self->mason( Jifty::View::Mason::Handler->new( $self->mason_config ) );

    $self->static_handler(Jifty::View::Static::Handler->new());

    return $self;
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
        preprocess => sub {
            # Force UTF-8 semantics on all our components by
            # prepending this block to all components as Mason
            # components defaults to parse the text as Latin-1
            ${$_[0]} =~ s!^!<\%INIT>use utf8;</\%INIT>\n!;
        },
        data_dir =>  Jifty::Util->absolute_path( Jifty->config->framework('Web')->{'DataDir'} ),
        allow_globals => [
            qw[ $JiftyWeb ],
            @{Jifty->config->framework('Web')->{'Globals'} || []},
        ],
        comp_root     => [ 
                          [application =>  Jifty::Util->absolute_path( Jifty->config->framework('Web')->{'TemplateRoot'} )],
                          [jifty => Jifty->config->framework('Web')->{'DefaultTemplateRoot'}],
                         ],
        %{ Jifty->config->framework('Web')->{'MasonConfig'} },
    );

    for my $plugin (Jifty->plugins) {
        my $comp_root = $plugin->template_root;
        next unless $comp_root;
        push @{ $config{comp_root} }, [ ref($plugin)."-".Jifty->web->serial => $comp_root ];
    }

    # In developer mode, we want halos, refreshing and all that other good stuff. 
    if (Jifty->config->framework('DevelMode') ) {
        push @{$config{'plugins'}}, 'Jifty::Mason::Halo';
        $config{static_source}    = 0;
        $config{use_object_files} = 0;
    }
    return (%config);
        
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

    Module::Refresh->refresh if ( Jifty->config->framework('DevelMode') );
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
