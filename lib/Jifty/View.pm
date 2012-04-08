package Jifty::View;
use strict;
use warnings;

use base qw/Jifty::Object/;
use Class::Trigger;

use Encode ();

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
    my $r = Jifty->web->response;

    # Send a header
    $r->content_type || $r->content_type('text/html; charset=utf-8'); # Set up a default

    # We now install a new, faster out_method that doesn't have to
    # keep checking whether headers have been sent.
    my $content = sub {
        Jifty->web->response->{body} .= $_
            for map { Encode::is_utf8($_) ? Encode::encode('utf8', $_)
                                          : $_ }
                @_;
    };
    Jifty->handler->buffer->out_method( $content );
    $content->(@_);
}

=head1 SEE ALSO

L<Jifty::View::Declare>, L<Jifty::View::Declare::BaseClass>, L<Jifty::View::Mason::Handler>

=head1 LICENSE

Jifty is Copyright 2005-2010 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut



1;
