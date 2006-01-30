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

=cut

use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors(qw(mason dispatcher));

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

Returns our Mason config.  We use the component root specified in the
C<Web/TemplateRoot> framework configuration variable (or C<html> by
default).  Additionally, we set up a C<jifty> component root, as
specified by the C<Web/DefaultTemplateRoot> configuration.  All
interpolations are HTML-escaped by default, and we use the fatal error
mode.

=cut

sub mason_config {
    return (
        allow_globals => [qw[$JiftyWeb]],
        comp_root     => [ 
                            [application =>  Jifty::Util->absolute_path( Jifty->config->framework('Web')->{'TemplateRoot'} || "html")],
                            [jifty => Jifty->config->framework('Web')->{'DefaultTemplateRoot'}
                                ]],
        error_mode => 'fatal',
        error_format => 'text',
        default_escape_flags => 'h',
        autoflush => 0,
        plugins => ['Jifty::Mason::Halo']
    );
}


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

    Module::Refresh->refresh;

    local $HTML::Mason::Commands::JiftyWeb = Jifty::Web->new();
    Jifty->web->request(Jifty::Request->new()->fill($args{cgi}));

    $self->mason(Jifty::MasonHandler->new(
        $self->mason_config,
        out_method => sub {
            my $m = HTML::Mason::Request->instance;
            my $r = $m->cgi_request;
            # Send headers if they have not been sent by us or by user.
            # We use instance here because if we store $request we get a
            # circular reference and a big memory leak.
            unless ($r->http_header_sent) {
                $r->send_http_header();
            }

            $r->content_type || $r->content_type('text/html; charset=utf-8'); # Set up a default

            if ($r->content_type =~ /charset=([\w-]+)$/ ) {
                my $enc = $1;
                binmode *STDOUT, ":encoding($enc)";
            }
            # We could perhaps install a new, faster out_method here that
            # wouldn't have to keep checking whether headers have been
            # sent and what the $r->method is.  That would require
            # additions to the Request interface, though.
            print STDOUT grep {defined} @_;
        },
    ));
    $self->mason->interp->set_escape(
        h => \&Jifty::Handler::escape_utf8 );
    $self->mason->interp->set_escape(
        u => \&Jifty::Handler::escape_uri );


    $self->dispatcher(Jifty->config->framework('ApplicationClass')."::Dispatcher");
    $self->dispatcher->require;
    $self->dispatcher->handle_request();

    $self->cleanup_request();

}

=head2 escape_utf8 SCALARREF

Does a css-busting but minimalist escaping of whatever html you're passing in.

=cut

sub escape_utf8 {
    my $ref = shift;
    my $val = $$ref;
    use bytes;
    $val =~ s/&/&#38;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\(/&#40;/g;
    $val =~ s/\)/&#41;/g;
    $val =~ s/"/&#34;/g;
    $val =~ s/'/&#39;/g;
    $$ref = $val;
    Encode::_utf8_on($$ref);

}

=head2 escape_uri SCALARREF

Escapes URI component according to RFC2396

=cut

use Encode qw();

sub escape_uri {
    my $ref = shift;
    $$ref = Encode::encode_utf8($$ref);
    $$ref =~ s/([^a-zA-Z0-9_.!~*'()-])/uc sprintf("%%%02X", ord($1))/eg;
    Encode::_utf8_on($$ref);
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
