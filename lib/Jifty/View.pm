package Jifty::View;
use strict;
use warnings;

use base qw/Jifty::Object/;

=head1 NAME

Jifty::View - Base class for view modules

=head1 DESCRIPTION

This is the base class for L<Jifty::View::Declare> and L<Jifty::View::Mason::Handler>, which are the two view plugins shipped with Jifty. Other view plugins can be built by extending this class.

=head1 METHODS

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
    Jifty->web->session->set_cookie;
    my $r = Jifty->handler->apache;

    $r->content_type || $r->content_type('text/html; charset=utf-8'); # Set up a default

    unless ( $r->http_header_sent or not __PACKAGE__->auto_send_headers ) {
        Jifty->handler->send_http_header;
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

=head1 SEE ALSO

L<Jifty::View::Declare>, L<Jifty::View::Declare::BaseClass>, L<Jifty::View::Mason::Handler>

=head1 LICENSE

Jifty is Copyright 2005-2007 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut



1;
