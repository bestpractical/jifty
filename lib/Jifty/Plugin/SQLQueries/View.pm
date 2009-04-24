package Jifty::Plugin::SQLQueries::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

template '/__jifty/admin/requests/queries' => sub {
    my $request_inspector = Jifty->find_plugin('Jifty::Plugin::RequestInspector');
    my $id = get('id');
    my $log = $request_inspector->get_plugin_data($id, 'Jifty::Plugin::SQLQueries');

    ol {
        for (my $query_id = 0; $query_id < @$log; ++$query_id) {
            my $query = $log->[$query_id][1];
            li {
                hyperlink(
                    label => $query,
                    onclick => {
                        element   => "#query-$id-$query_id",
                        replace_with => '/__jifty/admin/requests/query',
                        toggle    => 1,
                        effect    => 'slideDown',
                        arguments => {
                            id       => $id,
                            query_id => $query_id,
                        },
                    },
                );

                div { attr { id is "query-$id-$query_id" } };
            };
        }
    }
};

template '/__jifty/admin/requests/query' => sub {
    my $request_inspector = Jifty->find_plugin('Jifty::Plugin::RequestInspector');
    my $id       = get('id');
    my $query_id = get('query_id');

    my $log = $request_inspector->get_plugin_data($id, 'Jifty::Plugin::SQLQueries');

    my $query_log = $log->[$query_id];

    my ($timestamp, $query, $binds, $duration, $plugins) = @$query_log;
    my $stack_trace = $plugins->{SQLQueryPlugin};

    h3 { "Bind Parameters" }
    ol {
        li { $_ } for @$binds;
    }

    h3 { "Stack Trace" }
    pre { $stack_trace }
};

1;

