use warnings;
use strict;

package Jifty::Collection;

use base qw/Jifty::Object Jifty::DBI::Collection Class::Accessor::Fast/;
use Data::Page;

=head1 NAME

Jifty::Collection - Collection of Jifty::Record objects

=head1 SYNOPSIS

  package Foo::Model::BarCollection
  use base qw/Jifty::Collection/;

=head1 DESCRIPTION

This is a wrapper over L<Jifty::DBI::Collection> that at the same time
is a L<Jifty::Object>.  To use it, subclass it.

Alternatively, an 'anonymous' collection can be made by creating a new
C<Jifty::Collection> object, and calling
C<record_class('Application::Model::Foo')> or similar on it.

In addition, each L<Jifty::Collection> includes a L<Data::Page> object
to help with calculations related to paged data.  You should B<not>
call the C<first_row> and C<rows_per_page> methods from
L<Jifty::DBI::Collection> on a L<Jifty::Collection>.  Instead, if
you'd like to use paging, you should use the C<set_page_info> method
to B<set> the number of records per page and first record on the
current page, and you should use the L<Data::Page> object returned by
the C<pager> method to B<get> information related to paging.

=head1 MODEL

=head2 pager

Returns a L<Data::Page> object associated with this collection.  This
object defaults to 10 entries per page.  You should use only use
L<Data::Page> methods on this object to B<get> information about
paging, not to B<set> it; use C<set_page_info> to set paging
information.

=head2 results_are_readable

If your results from the query are guaranteed to be readable by
current_user, you can create the collection with
C<< results_are_readable => 1 >>.  This causes check_read_rights to bypass
normal current_user_can checks.

=cut

__PACKAGE__->mk_accessors(qw/results_are_readable/);

=head2 as_search_action PARAMHASH

Returns the L<Jifty::Action::Record::Search> action for the model
associated with this collection.

The PARAMHASH allows you to add additional parameters to pass to
L<Jifty::Web/new_action>.

=cut

sub as_search_action {
    my $self = shift;
    return $self->record_class->as_search_action(@_);
}

=head2 add_record

If L</results_are_readable> is false, only add records to the
collection that we can read (by checking
L<Jifty::Record/check_read_rights>). Otherwise, make sure all records
added are readable.

=cut

sub add_record {
    my $self = shift;
    my ($record) = (@_);

    # If results_are_readable is set, guarantee that they are
    $record->_is_readable(1)
        if $self->results_are_readable;

    # Only add a record if results_are_readable or the user has read rights
    $self->SUPER::add_record($record)
        if $self->results_are_readable || $record->check_read_rights;
}

# Overrides the _init method of Jifty::DBI::Collection and is called by new.
# This does the following:
#
#  - Sets up the current user
#  - Sets up the record class, if given as an argument
#  - Sets up results_are_readable, if given as an argument
#  - Sets up the table used for storage
#
sub _init {
    my $self = shift;
    my %args = (
        record_class         => undef,
        current_user         => undef,
        results_are_readable => undef,
        @_
    );

    # Setup the current user, record class, results_are_readable
    $self->_get_current_user(%args);
    $self->record_class( $args{record_class} ) if defined $args{record_class};
    $self->results_are_readable( $args{results_are_readable} );

    # Bad stuff, we really need one of these
    unless ( $self->current_user ) {
        Carp::confess("Collection created without a current user");
    }

    # Setup the table and call the super-implementation
    $self->table( $self->new_item->table() );
    $self->SUPER::_init(%args);
}

=head2 implicit_clauses

Defaults to ordering by the C<id> column.

=cut

sub implicit_clauses {
    my $self = shift;
    $self->order_by( column => 'id', order => 'asc' );
}

sub _new_record_args {
    my $self = shift;
    return ( current_user => $self->current_user );
}

sub _new_collection_args {
    my $self = shift;
    return ( current_user => $self->current_user );
}

=head2 jifty_serialize_format

This returns an array reference of the individual records that make up this
collection.

=cut

sub jifty_serialize_format {
    my $records = shift->items_array_ref;

    return [ map { $_->jifty_serialize_format(@_) } @$records ];
}

=head1 SEE ALSO

L<Jifty::DBI::Collection>, L<Jifty::Object>, L<Jifty::Record>

=head1 LICENSE

Jifty is Copyright 2005-2010 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
