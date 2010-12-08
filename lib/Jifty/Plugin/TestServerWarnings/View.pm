use strict;
use warnings;

package Jifty::Plugin::TestServerWarnings::View;
use Jifty::View::Declare -base;

=head1 NAME

Jifty::Plugin::TestServerWarnings::View - Downloads test warnings

=head1 TEMPLATES

=head2 C<__jifty/test_warnings>

Outputs L<Jifty::Plugin::TestServerWarnings/encoded_warnings> to the
client.

=cut

template "/__jifty/test_warnings" => sub {
    my $plugin = Jifty->find_plugin('Jifty::Plugin::TestServerWarnings');
    Jifty->web->response->content_type("application/x-perl");
    outs_raw($plugin->encoded_warnings);
};

1;

