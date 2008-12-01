use 5.008;
use utf8;
use strict;
use warnings;

package Jifty::Plugin::Tag::Mixin::Collection;

use base qw(Exporter);

our @EXPORT = qw(limit_by_tag);

sub import {
    my $self = shift;
    my $caller = caller;
    $self->export_to_level(1,undef);
}

my $tags_table = sub {
    return Jifty->app_class('Model', 'Tag')->table;
};

sub limit_by_tag {
    my $self  = shift;
    my $value = shift;
    my %opt   = @_;

    $value = '' unless defined $value;
    my $not = $value =~ s/^!//;

    my $alias = $self->join(
        type    => 'LEFT',
        column1 => 'id',
        table2  => $tags_table->(),
        column2 => 'record',
    );
    $self->limit(
        leftjoin => $alias,
        alias => $alias,
        column => 'model',
        value => ($self->record_class =~ /([^:]+)$/)[0],
    );

    if ( length $value ) {
        unless ( $not ) {
            $self->limit(
                %opt,
                alias => $alias,
                column => 'value',
                value => $value,
            );
        } else {
            $self->limit(
                leftjoin => $alias,
                alias => $alias,
                column => 'value',
                value => $value,
            );
            $self->limit(
                %opt,
                alias => $alias,
                column => 'record',
                operator => 'IS',
                value => 'NULL',
            );
        }
    } else {
        $self->limit(
            %opt,
            alias => $alias,
            column => 'record',
            operator => $not? 'IS NOT': 'IS',
            value => 'NULL',
        );
    }
}

1;
