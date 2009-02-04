use strict;
use warnings;

package Jifty::Plugin::TestServerWarnings::View;
use Jifty::View::Declare -base;

template "/__jifty/test_warnings" => sub {
    my $plugin = Jifty->find_plugin('Jifty::Plugin::TestServerWarnings');
    Jifty->handler->apache->content_type("application/x-perl");
    outs_raw($plugin->encoded_warnings);
};

1;

