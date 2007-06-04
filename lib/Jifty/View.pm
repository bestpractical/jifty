package Jifty::View;
use strict;
use warnings;

=head2 auto_send_headers

Doesn't send headers if this is a subrequest (according to the current
L<Jifty::Request>).

=cut

sub auto_send_headers {
    return not Jifty->web->request->is_subrequest;
}

=head2 out_method

The default output method.  Sets the content-type to C<text/html;
charset=utf-8> unless a content type has already been set, and then
sends a header if need be.

=cut

sub out_method {
    my $r = Jifty->handler->apache;

    $r->content_type || $r->content_type('text/html; charset=utf-8'); # Set up a default

    unless ( $r->http_header_sent or not __PACKAGE__->auto_send_headers ) {
        $r->send_http_header();
    }

    # We could perhaps install a new, faster out_method here that
    # wouldn't have to keep checking whether headers have been
    # sent and what the $r->method is.  That would require
    # additions to the Request interface, though.
    binmode *STDOUT;
    if ( my ($enc) = $r->content_type =~ /charset=([\w-]+)$/ ) {
        print STDOUT map Encode::encode($enc, $_), grep {defined} @_;
    } else {
        print STDOUT grep {defined} @_;
    }
}


1;
