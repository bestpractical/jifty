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
use Module::Pluggable search_path => [ 'Jifty::Web::Form::Field' ];
use Scalar::Defer;

use Jifty::Record schema {
    column name => 
        type is 'text',
        label is 'Column name',
        is mandatory,
        is immutable;

    column model_class => 
        refers_to Jifty::Model::ModelClass,
        label is 'Model',
        is mandatory;

    column label_text => 
        type is 'text',
        label is 'Label';

    column hints => 
        type is 'text',
        label is 'Hints',
        hints is 'Additional hint to give with the label as to what kind of information is expected in this column.';

    # FIXME should be a ref to a list of storage types
    column storage_type => 
        type is 'text',
        label is 'Storage type',
        hints is 'The kind of data that is being stored. Use "text" if you are not sure.',
        is autocompleted;

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
        hints is 'The kind of widget to use to edit the information.',
        is autocompleted;

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
        default is 1;

    column writable => 
        type is 'boolean', 
        label is 'Writable?',
        hints is 'Can the value of this column be changed after created?',
        default is 1;

    column default_value => 
        type is 'text',
        label is 'Default value',
        hints is 'What value should be set for this column if none is given?';

    column distinct_value =>
        type is 'boolean',
        label is 'Distinct?',
        hints is 'Dinstinct columns require a unique value in every row.';

    # TODO Valid values are the list of available models or collections
    column refers_to_class =>
        type is 'text',
        label is 'Refers to';

    # TODO Should pull a list of columns from the refesr_to record_class
    column refers_to_by =>
        type is 'text',
        label is 'By';

    column virtual =>
        type is 'boolean',
        label is 'Virtual?',
        is mandatory,
        default is 0;
};

=head2 before_create

Before creating the column, make sure that columns get setup correctly.

=cut

sub before_create {
    my $self = shift;
    my $args = shift;

    # Referals need special treatment
    if (defined $args->{refers_to_class}) {

        # If "by" is set, it's going to be a virtual column
        if (defined $args->{refers_to_by} and $args->{refers_to_by}) {
            $args->{virtual} = 1;
        }

        # Refer to a record and your column needs to be an int
        elsif ($args->{refers_to_class}->isa('Jifty::DBI::Record')) {
            $args->{storage_type} = 'int';
        }

        # XXX Can a column refer to something else? -- sterling
    }

    return 1;
}

=head2 after_create

Upon creation of a metacolumn object, update the actual table to add an actual column.

=cut

sub after_create {
    my $self = shift;
    my $idref = shift;
    $self->load_by_cols(id => $$idref);
    $self->model_class->add_column($self);
    unless ($self->virtual) {
        my $class = $self->model_class->qualified_class;
        my $ret = Jifty->handle->simple_query( $class->add_column_sql( $self->name ) );
        my $mixins = $class->RECORD_MIXINS || [];
        for my $mixin (@$mixins) {
            if (my $triggers_for_column 
                    = $mixin->can('register_triggers_for_column')) {
                $triggers_for_column->($class, $self->name);
            }
        }
        $ret || $self->log->fatal( "error updating a table: " . $ret->error_message);
    }
    return 1;
}

=head2 after_delete

Cleans up triggers for a column. This way if a column of a given name is deleted and another column of the same name is created, the old triggers won't be overlaid on the new ones.

=cut

sub after_delete {
    my $self = shift;
    my $ret = shift;

    if ($$ret) {
        my $name = $self->name;

        delete $self->{__triggers}{'before_set_'.$name};
        delete $self->{__triggers}{'after_set_'.$name};
    }

    return 1;
}

=head2 table

Database-backed models are stored in the table C<_jifty_models>.

=cut

sub table {'_jifty_modelcolumns'}

=head2 since

The metadata table first appeared in Jifty version 0.70127

=cut

sub since {'0.70127'}

=head2 autocomplete_storage_type

This attempts to discover the available column types from the DBI handle using C<type_info>.

=cut

# XXX Should this information be cached?
sub autocomplete_storage_type {
    my ($self, $string) = @_;
    
    # Generic defaults
    # TODO These should be loaded from somewhere or a constant somewhere else?
    # TODO Add more default choices.
    my @choices = qw/
        text
        int
        timestamp
    /;

    if (Jifty->handle && Jifty->handle->dbh) {
        my @type_info = Jifty->handle->dbh->type_info;
        if (@type_info) {
            @choices = map { $_->{TYPE_NAME} } @type_info;
        }
    }

    my $qstring = $string ? quotemeta $string : '.*';
    my @matches = grep /$qstring/, @choices;

    return @matches;
}

=head2 autocomplete_render_as

Searches the list of Jifty form widgets to suggest options.

=cut

sub autocomplete_render_as {
    my ($self, $string) = @_;

    my $qstring = $string ? quotemeta $string : '.*';
    my @widgets = grep /$qstring/, map { /(\w+)$/ } $self->plugins;

    return @widgets;
}

1;
