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
            my $seconds = sprintf('%.2f', $log->[$query_id][3]);
            my $query = $log->[$query_id][1];
            my $label = _("(%1s) %2", $seconds, $query);

            li {
                hyperlink(
                    label => $label,
                    onclick => {
                        region    => Jifty->web->qualified_region("query_$query_id"),
                        replace_with => '/__jifty/admin/requests/query',
                        toggle    => 1,
                        effect    => 'slideDown',
                        arguments => {
                            id       => $id,
                            query_id => $query_id,
                        },
                    },
                );

                render_region("query_$query_id");
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
    my $stacktrace = $plugins->{SQLQueryPlugin_Stacktrace};
    my $explain    = $plugins->{SQLQueryPlugin_Explain};

    if (@{ $binds || [] }) {
        h3 { "Bind Parameters" }
        ol {
            li { $_ } for @$binds;
        }
    }

    if ($stacktrace) {
        h3 { "Stack Trace" }
        pre { $stacktrace }
    }

    if ($explain) {
        h3 { "Explain" }
        pre { join "\n", @{$explain} }
    }
};

1;

__END__

=head1 NAME

Jifty::Plugin::SQLQueries::View - View for SQLQueries

=cut

