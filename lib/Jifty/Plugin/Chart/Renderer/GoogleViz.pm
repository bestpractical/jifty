package Jifty::Plugin::Chart::Renderer::GoogleViz;
use strict;
use warnings;
use base 'Jifty::Plugin::Chart::Renderer';

use Jifty::JSON;

=head2 init

We need to load Google's JS.

=cut

sub init {
    my $self = shift;

    Jifty->web->add_external_javascript("http://www.google.com/jsapi");
}

=head2 render

=cut

sub render {
    my $self = shift;
    my $chart_id = 'chart_' . Jifty->web->serial;
    my $chart_class = $self->chart_class;
    my $load_params = objToJson {
        packages => [ $self->packages_to_load ],
    };
    my $draw_params = objToJson($self->draw_params);

    Jifty->web->out(<< "JS_HEADER");
        <script type="text/javascript">
            google.load('visualization', 1, $load_params);
            google.setOnLoadCallback(function () {
                var data = new google.visualization.DataTable();
JS_HEADER

    $self->render_data;

    Jifty->web->out(<< "JS_FOOTER");
                var chart = new $chart_class(document.getElementById('$chart_id'));
                chart.draw(data, $draw_params);
            });
        </script>
JS_FOOTER

    Jifty->web->out(qq{<div id="$chart_id"></div>});

    return;
}

1;

