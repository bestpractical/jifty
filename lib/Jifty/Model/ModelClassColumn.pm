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

use Jifty::Record schema {
    column name => type is 'text';
    column model_class => refers_to Jifty::Model::ModelClass;
    column label => type is 'text';
    column hints => type is 'text';
    column storage_type => type is 'text'; # should be a ref to a list
    column max_length => type is 'int';
    column sort_order => type is 'int';
    column validator => type is 'text'; # should be a ref to a list. or maybe take code
    column valid_values => type is 'text'; # should be a ref to a list. or maybe take code
    column canonicalizer => type is 'text'; # ditto
    column autocompleter => type is 'text'; # ditto
    column mandatory => type is 'boolean';
    column since_version => type is 'text';
    column render_as => type is 'text'; # should actually be a reference to  a list
    column filters => type is 'text'; # should actually be a reference to  a list
    column description => type is 'text'; 
    column indexed  => type is 'boolean';
    column readable => type is 'boolean', default is 'true';
    column writable => type is 'boolean', default is 'true';
    column default_value => type is 'text';
};


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
