use strict;
use warnings;

package Jifty::View::Mason::Handler;

=head1 NAME

Jifty::View::Mason::Handler - Handler for Mason requests inside of Jifty

=head1 SUMMARY

Jifty controls all of the input and output from the Mason templating
engine; this means that we cannot use the Mason's standard
L<HTML::Mason::CGIHandler> interface to interact with it.

=cut

use HTML::Mason;
use HTML::Mason::Utils;
use Params::Validate qw(:all);
use HTML::Mason::Exceptions;
use HTML::Mason::FakeApache;
use Encode qw();

use Class::Container;
use base qw(Class::Container);

use HTML::Mason::MethodMaker
    ( read_write => [ qw( interp ) ] );

use vars qw($VERSION);

__PACKAGE__->valid_params
    (
     interp => { isa => 'HTML::Mason::Interp' },
    );

__PACKAGE__->contained_objects
    (
     interp => 'HTML::Mason::Interp',
    );


=head2 new PARAMHASH

Takes a number of key-value parameters; see L<HTML::Mason::Params>.
Defaults the C<out_method> to L</out_method>, and the C<request_class>
to L<HTML::MAson::request::Jifty> (below).  Finally, adds C<h> and
C<u> escapes, which map to L</escape_uri> and L<escape_utf8>
respectively.

=cut

sub new {
    my $package = shift;

    my %p = @_;
    my $self = $package->SUPER::new( request_class => 'HTML::Mason::Request::Jifty',
                                     out_method => \&out_method,
                                     %p );
    $self->interp->compiler->add_allowed_globals('$r');
    $self->interp->set_escape( h => \&escape_utf8 );
    $self->interp->set_escape( u => \&escape_uri );

    return $self;
}


=head2 out_method

The default output method.  Sets the content-type to C<text/html;
charset=utf-8> unless a content type has already been set, and then
sends a header if need be.

=cut

sub out_method {
    my $m = HTML::Mason::Request->instance;
    my $r = Jifty->handler->apache;

    $r->content_type || $r->content_type('text/html; charset=utf-8'); # Set up a default

    if ($r->content_type =~ /charset=([\w-]+)$/ ) {
        my $enc = $1;
	if (lc($enc) =~ /utf-?8/) {
            # XXX TODO: utf8 binmode breaks things right now
            #    binmode *STDOUT, ":utf8";
	}
	else {
            binmode *STDOUT, ":encoding($enc)";
	}
    }

    unless ($r->http_header_sent or not $m->auto_send_headers) {
        $r->send_http_header();
    }

    # We could perhaps install a new, faster out_method here that
    # wouldn't have to keep checking whether headers have been
    # sent and what the $r->method is.  That would require
    # additions to the Request interface, though.
    print STDOUT grep {defined} @_;
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

sub escape_uri {
    my $ref = shift;
    $$ref = Encode::encode_utf8($$ref);
    $$ref =~ s/([^a-zA-Z0-9_.!~*'()-])/uc sprintf("%%%02X", ord($1))/eg;
    Encode::_utf8_on($$ref);
}


=head2 handle_comp COMPONENT

Takes a component path to render.  Deals with setting up a global
L<HTML::Mason::FakeApache> and Request object, and calling the
component.

=cut

sub handle_comp {
    my ($self, $comp) = (shift, shift);

    # Set up the global
    my $r = Jifty->handler->apache;
    $self->interp->set_global('$r', $r);

    my %args = $self->request_args($r);

    my @result;
    if (wantarray) {
        @result = eval { $self->interp->exec($comp, %args) };
    } elsif ( defined wantarray ) {
        $result[0] = eval { $self->interp->exec($comp, %args) };
    } else {
        eval { $self->interp->exec($comp, %args) };
    }

    if (my $err = $@) {
        my $retval = isa_mason_exception($err, 'Abort')   ? $err->aborted_value  :
                     isa_mason_exception($err, 'Decline') ? $err->declined_value :
                     rethrow_exception $err;

        # Unlike under mod_perl, we cannot simply return a 301 or 302
        # status and let Apache send headers, we need to explicitly
        # send this header ourself.
        $r->send_http_header if $retval && grep { $retval eq $_ } ( 200, 301, 302 );

        return $retval;
    }

    return wantarray ? @result : defined wantarray ? $result[0] : undef;
}

=head2 request_args

The official source for request arguments is from the current
L<Jifty::Request> object.

=cut

sub request_args {
    return %{Jifty->web->request->arguments};
}


###########################################################
package HTML::Mason::Request::Jifty;
# Subclass for HTML::Mason::Request object $m

=head1 HTML::Mason::Request::Jifty

Subclass of L<HTML::Mason::Request> which is customised for Jifty's use.

=cut

use HTML::Mason::Exceptions;
use HTML::Mason::Request;
use base qw(HTML::Mason::Request);

=head2 auto_send_headers

Doesn't send headers if this is a subrequest (according to the current
L<Jifty::Request>).

=cut

sub auto_send_headers {
    return not Jifty->web->request->is_subrequest;
}

=head2 exec

Actually runs the component; in case no headers have been sent after
running the component, and we're supposed to send headers, sends them.

=cut

sub exec
{
    my $self = shift;
    my $r = Jifty->handler->apache;
    my $retval;

    eval { $retval = $self->SUPER::exec(@_) };

    if (my $err = $@)
    {
	$retval = isa_mason_exception($err, 'Abort')   ? $err->aborted_value  :
                  isa_mason_exception($err, 'Decline') ? $err->declined_value :
                  rethrow_exception $err;
    }

    # On a success code, send headers if they have not been sent and
    # if we are the top-level request. Since the out_method sends
    # headers, this will typically only apply after $m->abort.
    if ($self->auto_send_headers
        and not $r->http_header_sent
        and (!$retval or $retval==200)) {
        $r->send_http_header();
    }
}

=head2 redirect

Calls L<Jifty::Web/redirect>.

=cut

sub redirect {
    my $self = shift;
    my $url = shift;

    Jifty->web->redirect($url);
}

1;
