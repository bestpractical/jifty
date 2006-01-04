use strict;
use warnings;

package Jifty::Handler;

=head1 NAME

Jifty::Handler - Methods related to the Mason handler

=head1 SYNOPSIS

  use Jifty;
  Jifty->new();

  my $cgihandler = HTML::Mason::CGIHandler->new( Jifty->handler->mason_config );

  # after each request is handled
  Jifty::Handler->cleanup_request;

=head1 DESCRIPTION

L<Jifty::Handler> provides methods required to deal with Mason CGI
handlers.  

=head2 new

Create a new Jifty::Handler object. Generally, Jifty.pm does this only once at startup.

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;

}


=head2 mason_config

Returns our Mason config.  We use C<Jifty::MasonInterp> as our Mason
interpreter, and have a component root as specified in the
C<Web/TemplateRoot> framework configuration variable (or C<html> by
default).  Additionally, we set up a C<jifty> component root, as
specified by the C<Web/DefaultTemplateRoot> configuration.  All
interpolations are HTML-escaped by default, and we use the fatal error
mode.

=cut

sub mason_config {
    return (
        allow_globals => [qw[$JiftyWeb]],
        interp_class  => 'Jifty::MasonInterp',
        comp_root     => [ 
                            [application =>  Jifty::Util->absolute_path( Jifty->config->framework('Web')->{'TemplateRoot'} || "html")],
                            [jifty => Jifty->config->framework('Web')->{'DefaultTemplateRoot'}
                                ]],
        error_mode => 'fatal',
        error_format => 'text',
        default_escape_flags => 'h',
        #       plugins => ['Jifty::SetupRequest']
    );
}


=head2 handle_request

When your server processs (be it Jifty-internal, FastCGI or anything else) wants
to handle a request coming in from the outside world, you should call C<handle_request>.
It expects a few parameters. C<cgi> is required. 

=over

=item cgi

A L<CGI>.pm object that your server has already set up and loaded with your request's data

=item mason_handler

An initialized L<HTML::Mason> CGIHandler or subclass. 

=item

=back

=cut


sub handle_request {
    my $self = shift;
    my %args = (
        mason_handler => undef,
        cgi           => undef,
        @_
    );

    my $handler = $args{'mason_handler'};
    my $cgi     = $args{'cgi'};
    if ( ( !$handler->interp->comp_exists( $cgi->path_info ) )
        && ($handler->interp->comp_exists( $cgi->path_info . "/index.html" ) )
        )
    {
        $cgi->path_info( $cgi->path_info . "/index.html" );
    }
    Module::Refresh->refresh;
    local $HTML::Mason::Commands::JiftyWeb = Jifty::Web->new();

    eval { $handler->handle_cgi_object($cgi); };
    $self->cleanup_request();

}

=head2 cleanup_request

Dispatchers should call this at the end of each request, as a class method.
It flushes the session to disk, as well as flushing L<Jifty::DBI>'s cache. 

=cut

sub cleanup_request {
    # Clean out the cache. the performance impact should be marginal.
    # Consistency is improved, too.
    Jifty->web->session->unload();
    Jifty::Record->flush_cache;
}

1;
