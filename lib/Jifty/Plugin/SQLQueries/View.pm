package Jifty::Plugin::SQLQueries::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

template '/__jifty/admin/requests/query' => sub {
    my $request_inspector = Jifty->find_plugin('Jifty::Plugin::RequestInspector');
    my $id = get('id');
    my $log = $request_inspector->get_plugin_data($id, 'Jifty::Plugin::SQLQueries');

    ol {
        for (@$log) {
            li { $_->[1] };
        }
    }
};

1;

