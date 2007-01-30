use strict;
use warnings;

package Jifty::Plugin::Schema::ModelBuilder::Model::ModelAttribute;

use Jifty::Plugin::Schema::ModelBuilder::Model::ModelColumn;

use Jifty::DBI::Schema;
use Jifty::Record schema {
    column XXparent_column =>
        refers_to Jifty::Plugin::Schema::ModelBuilder::Model::ModelColumn,
        label is 'Column';

    column XXname =>
        type is 'text',
        label is 'Trait name',
        is mandatory,
        valid_values are qw/
            refers_to
            by
            type
            default
            literal
            immutable
            unreadable
            max_length
            mandatory
            autocompleted
            distinct
            virtual
            sort_order
            input_filters
            since
            till
            valid_values
            label
            hints
            render_as
            indexed
        /;

    column XXtrait_argument =>
        type is 'text',
        label is 'Trait argument';
};

=head1 NAME

Jifty::Plugin::Schema::ModelBuilder::Model::Attribute - Model representing Jifty column attributes

=head1 SYNOPSIS

 my $model = Jifty::Plugin::Schema::ModelBuilder::Model::Table->new;
 $model->load_by_cols( name => 'SomeTable' );

 my $columns = $model->columns;
 while (my $column = $columns->next) {
     print "column ", $column->name, " =>\n";

     my $attributes = $model->attributes;
     while (my $attribute = $attributes->next) {
         print "\t", $attribute->as_jifty_attribute, ", "\n";
     }

     print ";\n\n";
 }

=head1 DESCRIPTION

Each object of this class represents an individual column trait assigned to a particular column.


=head1 AUTHORS

Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
