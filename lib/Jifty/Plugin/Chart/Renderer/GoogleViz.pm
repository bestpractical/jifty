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

    $self->render_data(%args);

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

=head2 render_data

Renders the columns and the data.

=cut

sub render_data {
    my $self = shift;
    my %args = @_;

    $self->add_columns(%args);
    $self->add_data(%args);
}

=head2 add_columns

Adds the columns to the visualization. Each column is a key-value pair; the key
is the column's C<id> and the value is either a string (the C<type>) or a
hashref. The hashref may specify C<type> and C<label>. If no C<label> is given,
the C<id> is used.

=cut

sub add_columns {
    my $self = shift;
    my %args = @_;

    my %cols = %{ $args{columns} };

    for my $id (keys %cols) {
        my $column = $cols{$id};

        my ($type, $label);
        if (ref($column)) {
            $type  = $column->{type};
            $label = $column->{label};
        }
        else {
            $type = $column;
        }

        $label ||= $id;

        Jifty->web->out("data.addColumn('$type', '$label', '$id');\n");
    }
}

=head2 add_data

Adds the data to the chart. Each data point should be a hash reference of
column id to value.

=cut

sub add_data {
    my $self = shift;
    my %args = @_;

    my @data = @{ $args{data} };

    Jifty->web->out('data.addRows(' . scalar(@data) . ");\n");

    my $row = 0;
    for my $datapoint (@data) {
        for my $column (keys %$datapoint) {
            my $value = $datapoint->{$column};
            my $encoded = objToJson($value);

            Jifty->web->out("data.setValue($row, '$column', $encoded);\n");
        }

        ++$row;
    }
}

1;

