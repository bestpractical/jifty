use warnings;
use strict;

=head1 NAME

Jifty::Model::ModelClassColumn - Tracks Jifty-related metadata

=head1 SYNOPSIS


=head1 DESCRIPTION

Every Jifty application automatically inherits this table, which
describes information about Jifty models which are stored only in the
database.  It uses this information to construct new model classes on
the fly as they're required by the application.

=cut

package Jifty::Model::ModelClassColumn;
use base qw( Jifty::Record );

use Jifty::DBI::Schema;
use Jifty::Model::ModelClass;
use Scalar::Defer;

use Jifty::Record schema {
    column name => 
        type is 'text',
        label is 'Column name',
        is mandatory;

    column model_class => 
        refers_to Jifty::Model::ModelClass,
        label is 'Model',
        is mandatory;

    column label => 
        type is 'text',
        label is 'Label';

    column hints => 
        type is 'text',
        label is 'Hints',
        hints is 'Additional hint to give with the label as to what kind of information is expected in this column.';

    # FIXME should be a ref to a list of storage types
    column storage_type => 
        type is 'text',
        label is 'type',
        hints is 'The kind of data that is being stored. Use "text" if you are not sure.';

    column max_length => 
        type is 'int',
        label is 'Max. length',
        hints is 'If set, any text greater than this length will be cut off before saving to the database.';

    column sort_order => 
        type is 'int',
        label is 'Sort order',
        hints is 'The order this column should be listed in relationship to the other columns.';

    # TODO How to handle code refs and such?
    column validator => 
        type is 'text',
        label is 'Validator',
        render_as 'Textarea';

    # TODO How to handle code or list refs and such?
    column valid_values => 
        type is 'text',
        label is 'Valid values',
        render_as 'Textarea';

    # TODO How to handle code refs and such?
    column canonicalizer => 
        type is 'text',
        label is 'Canonicalizer',
        render_as 'Textarea';

    # TODO How to handle code refs and such?
    column autocompleter => 
        type is 'text',
        label is 'Autocompleter',
        render_as 'Textarea';

    column mandatory => 
        type is 'boolean',
        label is 'Mandatory?',
        hints is 'If checked, a value must be given in this column in every row.';

    # FIXME should actually be a reference to  a list
    column render_as => 
        type is 'text',
        label is 'Render as',
        hints is 'The kind of widget to use to edit the information.';

    # FIXME should actually be a reference to  a list
    column filters => 
        type is 'text',
        label is 'Filters',
        hints is 'A list of Jifty::DBI filters to modify the data before going into or coming out of the database.';
        
    column description => 
        type is 'text',
        label is 'Description',
        render_as 'Textarea'; 

    column indexed  => 
        type is 'boolean',
        label is 'Indexed?',
        hints is 'Should the database index this column for faster searching.';

    column readable => 
        type is 'boolean', 
        label is 'Readable?',
        hints is 'Can the value of this column be read directly? For example, passwords should not normally be readable.',
        default is 'true';

    column writable => 
        type is 'boolean', 
        label is 'Writable?',
        hints is 'Can the value of this column be changed after created?',
        default is 'true';

    column default_value => 
        type is 'text',
        label is 'Default value',
        hints is 'What value should be set for this column if none is given?';

    column distinct_value =>
        type is 'boolean',
        label is 'Distinct?',
        hints is 'Dinstinct columns require a unique value in every row.';

    # TODO Should be a list of models or collections
    column refers_to =>
        type is 'text',
        label is 'Refers to';

    # TODO Should pull a list of columns from the refesr_to record_class
    column refer_to_by =>
        type is 'text',
        label is 'By';
};

=head2 after_create

Upon creation of a metacolumn object, update the actual table to add an actual column.

=cut

sub after_create {
    my $self = shift;
    my $idref = shift;
    $self->load_by_cols(id => $$idref);
    $self->model_class->add_column($self);

    my $ret = Jifty->handle->simple_query( $self->model_class->qualified_class->add_column_sql( $self->name ) );
    $ret or die "error updating a table: " . $ret->error_message;
}

=head2 table

Database-backed models are stored in the table C<_jifty_models>.

=cut

sub table {'_jifty_modelcolumns'}

=head2 since

The metadata table first appeared in Jifty version 0.70127

=cut

sub since {'0.70127'}

1;
