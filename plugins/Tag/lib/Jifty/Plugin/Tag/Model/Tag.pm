use 5.008;
use utf8;
use strict;
use warnings;

package Jifty::Plugin::Tag::Model::Tag;
use Jifty::DBI::Schema;

use Scalar::Util qw(blessed);

=head1 NAME

Jifty::Plugin::Tag::Model::Tag - tags attached to anything

=head1 SYNOPSIS

=head1 DESCRIPTION

This model is the repository for all comments in your application, if you use the L<Jifty::Plugin::Comment> plugin.

=head1 SCHEMA

=cut

use Jifty::Record schema {
    column model =>
        type is 'varchar(32)',
        label is _('Model name'),
        is mandatory,
        ;
    column record =>
        type is 'int',
        label is _('ID'),
        is mandatory,
        ;
    column value =>
        type is 'varchar(32)',
        label is _('Value'),
        is mandatory,
        ;
};

sub create {
    my $self = shift;
    my %args = @_;
    if ( my $class = blessed $args{'record'} ) {
        $args{'model'} = ($class =~ /([^:]+)$/)[0];
        $args{'record'} = $args{'record'}->id;
    }
    return $self->SUPER::create( %args );
}

sub canonicalize_value {
    my ($self, $value) = @_;
    return $value unless defined $value;

    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    $value =~ s/\s/ /g;
    return $value;
}

sub validate_value {
    my ($self, $value, $create_args) = @_;

    return (0, _('Characters [!,"] are not allowed in tags'))
        if $value =~ /[!,"]/;

    return 1;
}

sub record {
    my $self = shift;
    return Jifty->app_class('Model', $self->model)->load( $self->_value('record', @_) );
}

sub record_id {
    return (shift)->_value('record', @_);
}

sub used_by {
    my $self = shift;
    my %opt = @_;

    my $this_model   = $self->model;
    my $target_model = $opt{'model'} || $this_model;

    my $res = Jifty->app_class('Model', $target_model.'Collection')->new;
    $res->limit( column => 'id', operator => '!=', value => $self->record_id )
        if $this_model eq $target_model && !$opt{'include_this'};
    my $alias = $res->join( column1 => 'id', table2 => $self->table, column2 => 'record' );
    $res->limit( leftjoin=> $alias, alias => $alias, column => 'model', value => $target_model );
    $res->limit( alias => $alias, column => 'value', value => $self->value );
    return $res;
}

1;
