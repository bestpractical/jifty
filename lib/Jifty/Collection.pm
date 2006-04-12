use warnings;
use strict;

package Jifty::Collection;

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
use the C<first_row> and C<rows_per_page> methods from
L<Jifty::DBI::Collection> on a L<Jifty::Collection>.  Instead, if
you'd like to use paging, you should use the C<set_page_info> method
to B<set> the number of records per page and first record on the
current page, and you should use the L<Data::Page> object returned by
the C<pager> method to B<get> information related to paging.

=cut

use base qw/Jifty::Object Jifty::DBI::Collection Class::Accessor::Fast/;
use Data::Page;

=head1 MODEL

=head2 pager

Returns a L<Data::Page> object associated with this collection.  This
object defaults to 10 entries per page.  You should use only use
L<Data::Page>  methods on this object to B<get> information about paging,
not to B<set> it; use C<set_page_info> to set paging information.

=cut

__PACKAGE__->mk_accessors(qw(pager));

=head2 add_record

Only add records to the collection that we can read

=cut

sub add_record {
    my $self = shift;
    my($record) = (@_);
    $self->SUPER::add_record($record) if $record->current_user_can("read");
}

sub _init {
    my $self = shift;

    my %args = (
        record_class => undef,
        current_user => undef,
        @_
    );

    $self->_get_current_user(%args);
    $self->record_class($args{record_class}) if defined $args{record_class};
    unless ($self->current_user) {
        Carp::confess("Collection created without a current user");
    }
    $self->table($self->new_item->table());
    $self->SUPER::_init(%args);
}

=head2 implicit_clauses

Defaults to ordering by the C<id> column.

=cut

sub implicit_clauses {
    my $self = shift;
    $self->order_by( column => 'id',order => 'asc');
}

=head2 new_item

Overrides L<Jifty::DBI::Collection>'s new_item to pass in the current
user.

=cut

sub new_item {
    my $self = shift;
    my $class =$self->record_class();

    # We do this as a performance optimization, so we don't need to do the stackwalking to find it
    return $class->new(current_user => $self->current_user);
}

1;
