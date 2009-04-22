package Jifty::Plugin::RequestInspector::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

template '/__jifty/admin/requests' => page {
    my $request_inspector = Jifty->find_plugin('Jifty::Plugin::RequestInspector');

    table {
        for my $request ($request_inspector->requests) {
            row {
                cell { $request->{url} };
            };
        }
    };
};

1;

