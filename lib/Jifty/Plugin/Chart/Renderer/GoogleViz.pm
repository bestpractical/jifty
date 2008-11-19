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

    my $cols = $self->add_columns(%args);
    $self->add_data(%args, columns => $cols);
}

=head2 add_columns

Adds the columns to the visualization. Each column is a key-value pair; the key
is the column's C<id> and the value is either a string (the C<type>) or a
hashref. The hashref may specify C<type> and C<label>. If no C<label> is given,
the C<id> is used.

It will return a hashref of canonicalized columns.

=cut

sub add_columns {
    my $self = shift;
    my %args = @_;

    my $index = 0;
    my @cols = @{ $args{columns} };
    my %canonicalized_columns;

    while (my ($name, $column) = splice @cols, 0, 2) {
        my ($type, $label);
        if (ref($column)) {
            $type  = $column->{type};
            $label = $column->{label};
        }
        else {
            $type = $column;
        }

        $label ||= $name;

        $canonicalized_columns{$name} = {
            type  => $type,
            label => $label,
            index => $index++,
        };

        Jifty->web->out("data.addColumn('$type', '$label', '$name');\n");
    }

    return \%canonicalized_columns;
}

=head2 add_data

Adds the data to the chart. Each data point should be a hash reference of
column id to value.

=cut

sub add_data {
    my $self = shift;
    my %args = @_;

    my @data = @{ $args{data} };
    my $cols = $args{columns};

    Jifty->web->out('data.addRows(' . scalar(@data) . ");\n");

    my $row = 0;
    for my $datapoint (@data) {
        for my $column (keys %$datapoint) {
            my $col = $cols->{$column}
                or die "Invalid column id '$column'";

            my $value = $self->encode_value(
                value  => $datapoint->{$column},
                column => $col,
            );
            my $cid = $col->{index};

            Jifty->web->out("data.setValue($row, $cid, $value);\n");
        }

        ++$row;
    }
}

=head2 encode_value

=cut

sub encode_value {
    my $self = shift;
    my %args = @_;

    my $value  = $args{value};
    my $column = $args{column};

    if ($column->{type} eq 'date') {
        if (!ref($value)) {
            $value = Jifty::DateTime->new_from_string($value);
        }

        if (ref($value)) {
            if ($value->isa('Jifty::DateTime') && $value->is_date) {
                return sprintf 'new Date(%d, %d, %d)',
                    $value->year,
                    $value->month,
                    $value->day;
            }
            elsif ($value->isa('DateTime')) {
                return sprintf 'new Date(%d, %d, %d, %d, %d, %d)',
                    $value->year,
                    $value->month,
                    $value->day,
                    $value->hour,
                    $value->minute,
                    $value->second;
            }
        }

        die "Can't handle the date '$value'";
    }

    return objToJson($value);
}

1;

