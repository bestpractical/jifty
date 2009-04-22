package Jifty::Plugin::RequestInspector::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

template '/__jifty/admin/requests' => page {
    title => "Request Inspector"
}
content {
    my $request_inspector = Jifty->find_plugin('Jifty::Plugin::RequestInspector');

    ol {
        attr { id is 'request-inspector' };

        for my $request ($request_inspector->requests) {
            li {
                my $id = $request->{id};
                attr { id is "request-$id" };

                hyperlink(
                    label => $request->{url},
                    onclick => {
                        element => "#request-$id",
                        append  => '/__jifty/admin/requests/plugins',
                        toggle  => 1,
                        effect  => 'slideDown',
                        arguments => {
                            id => $id,
                        },
                    },
                );

                outs sprintf ' (%.2gs)',  $request->{end} - $request->{start};
            };
        }
    };
};

1;

