package Jifty::Plugin::RequestInspector::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

template '/__jifty/admin/requests' => page {
    title => "Request Inspector"
}
content {
    h2 { "Request Inspector" };

    render_region(
        name => 'request_inspector',
        path => '/__jifty/admin/requests/requests',
    );

    div {
        hyperlink(
            label => "Clear requests",
            onclick => {
                refresh => 'request_inspector',
                args => {
                    clear_requests => 1,
                },
            },
        ),
    };
};

template '/__jifty/admin/requests/requests' => sub {
    my $request_inspector = Jifty->find_plugin('Jifty::Plugin::RequestInspector');
    $request_inspector->clear_requests if get('clear_requests');

    ol {
        attr { id is 'request_inspector' };

        for my $request ($request_inspector->requests) {
            _render_request($request);
        }
    };

    render_region(
        name => 'more_button',
        path => '/__jifty/admin/requests/more_button',
    );
};

template '/__jifty/admin/requests/more_button' => sub {
    my $request_inspector = Jifty->find_plugin('Jifty::Plugin::RequestInspector');
    my $last_id = $request_inspector->last_id;

    hyperlink(
        label => "Load subsequent requests",
        onclick => [{
            element => '#request_inspector',
            append  => '/__jifty/admin/requests/more_requests',
            effect  => 'slideDown',
            arguments => {
                last_id => $last_id,
            },
        },
        {
            refresh_self => 1,
        }],
    );
};

template '/__jifty/admin/requests/more_requests' => sub {
    my $request_inspector = Jifty->find_plugin('Jifty::Plugin::RequestInspector');
    my $last_id = get('last_id');

    my @requests = $request_inspector->requests( after => $last_id );

    for my $request (@requests) {
        _render_request($request);
    }
};

template '/__jifty/admin/requests/plugins' => sub {
    my $id = get('id');
    my $request_inspector = Jifty->find_plugin('Jifty::Plugin::RequestInspector');

    dl {
        for my $plugin ($request_inspector->inspector_plugins) {
            my $plugin_name = ref $plugin;
            my $plugin_data = $request_inspector->get_plugin_data($id, $plugin_name);
            next if !defined($plugin_data);

            dt {
                (my $short_name = $plugin_name) =~ s/^Jifty::Plugin:://;
                if ($plugin->can('inspect_render_analysis')) {
                    hyperlink(
                        label => $short_name,
                        onclick => {
                            region => Jifty->web->qualified_region($plugin_name),
                            replace_with => '/__jifty/admin/requests/plugin',
                            toggle  => 1,
                            effect  => 'slideDown',
                            arguments => {
                                id => $id,
                                plugin_name => $plugin_name,
                            },
                        },
                    );
                }
                else {
                    outs $short_name;
                }
            };
            dd {
                if ($plugin->can('inspect_render_summary')) {
                    outs $plugin->inspect_render_summary($plugin_data, $id);
                }
                render_region($plugin_name);
            };
        }
    };
};

template '/__jifty/admin/requests/plugin' => sub {
    my $id = get('id');
    my $plugin_name = get('plugin_name');

    my $request_inspector = Jifty->find_plugin('Jifty::Plugin::RequestInspector');
    my $plugin_data = $request_inspector->get_plugin_data($id, $plugin_name);

    my $plugin = Jifty->find_plugin($plugin_name)
        or abort(404);

    $plugin->inspect_render_analysis($plugin_data, $id);
};

sub _render_request {
    my $request = shift;

    li {
        my $id = $request->{id};

        hyperlink(
            label => $request->{url},
            onclick => {
                region       => Jifty->web->qualified_region("request_$id"),
                replace_with => '/__jifty/admin/requests/plugins',
                toggle    => 1,
                effect    => 'slideDown',
                arguments => {
                    id => $id,
                },
            },
        );

        outs sprintf ' (%.2gs)',  $request->{end} - $request->{start};
        if ($request->{cookie}) {
            outs " [" . $request->{cookie} . "]";
        }

        render_region("request_$id");
    };
}

1;

__END__

=head1 NAME

Jifty::Plugin::RequestInspector::View - View for RequestInspector

=cut

