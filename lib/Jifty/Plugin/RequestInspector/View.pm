package Jifty::Plugin::RequestInspector::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

template '/__jifty/admin/requests' => page {
    my $request_inspector = Jifty->find_plugin('Jifty::Plugin::RequestInspector');

    table {
        for my $request ($request_inspector->requests) {
            row {
                cell { $request->{id} };
                cell { $request->{url} };
                cell { sprintf '%.2gs', $request->{end} - $request->{start} };
            };
            row {
                for my $plugin_name (keys %{ $request->{plugin_data} }) {
                    my $plugin_data = $request->{plugin_data}{$plugin_name};
                    my $plugin = Jifty->find_plugin($plugin_name);

                    my $summary = $plugin->inspect_render_summary($plugin_data);
                    next if !defined($summary);

                    $plugin_name =~ s/^Jifty::Plugin:://;
                    cell { $plugin_name };
                    cell { $summary };
                }
            };
        }
    };
};

1;

