package Jifty::Plugin::Chart::Renderer::GoogleViz;
use strict;
use warnings;
use base 'Jifty::Plugin::Chart::Renderer';

use Jifty::JSON 'objToJson';

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
    my %args = @_;

    my $chart_id = 'chart_' . Jifty->web->serial;
    my $chart_class = $self->chart_class;
    my $load_params = objToJson($self->load_params);
    my $draw_params = objToJson($self->draw_params);
    my $callback_name = 'callback_' . Jifty->web->serial;

    Jifty->web->out(<< "JS_HEADER");
        <script type="text/javascript">
            google.load('visualization', 1, $load_params);
            google.setOnLoadCallback($callback_name);
            function $callback_name() {
                var data = new google.visualization.DataTable();
JS_HEADER

    $self->render_data(%args));

    Jifty->web->out(<< "JS_FOOTER");
                var chart = new $chart_class(document.getElementById('$chart_id'));
                chart.draw(data, $draw_params);
            }
        </script>
JS_FOOTER

    Jifty->web->out(qq{
        <div
            style="width: $args{width}; height: $args{height};"
            id="$chart_id"
        ></div>
    });

    return;
}

=head2 load_params

Load the "packages" required for the visualization; define a
C<packages_to_load> method which returns a list of them.

=cut

sub load_params {
    my $self = shift;

    return {
        packages => [ $self->packages_to_load ],
    };
}

1;

