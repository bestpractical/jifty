use strict;
use warnings;

package Jifty::Plugin::Schema::ModelBuilder::Model::ModelColumn;

use Jifty::Plugin::Schema::ModelBuilder::Model::ModelTable;
use Jifty::Plugin::Schema::ModelBuilder::Model::ModelAttribute;

use Jifty::DBI::Schema;
use Jifty::Record schema {
    column parent_table =>
        refers_to Jifty::Plugin::Schema::ModelBuilder::Model::ModelTable,
        label is 'Table';

    column name =>
        type is 'text',
        label is 'Column name',
        is mandatory;

#    column model_attributes =>
#        refers_to Jifty::Plugin::Schema::ModelBuilder::Model::ModelAttributeCollection by 'parent_column';
};

=head1 NAME

Jifty::Plugin::Schema::ModelBuilder::Model::Column - Model representing Jifty columns

=head1 SYNOPSIS

 my $model = Jifty::Plugin::Schema::ModelBuilder::Model::Table->new
 $model->load_by_cols( name => 'SomeTable' );

 my $columns = $model->columns;
 while (my $column = $columns->next) {
     print "Column Name: ", $column->name, "\n";
 }

=head1 DESCRIPTION

Represents a single column attached to a model. The actual definition of the column is handled by the attributes associated with it.

=cut

sub model_attributes {
    my ($self) = @_;

    # XXX Very naughty! Hard-coded table name!
    my $attributes = Jifty->app('Model', 'ModelAttributeCollection');
    $attributes->limit( column => 'parent_column', value => $self->id );

    return $attributes;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
