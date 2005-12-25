use warnings;
use strict;

package JFDI::View::Helper::Collection;
use base qw/JFDI::View::Helper/;

use Data::Page;

=head1 STATE

L<JFDI::View::Helper::Collection> objects have a state variable called
current_page, which is 1-based.

=head1 METHODS


=head2 new

Creates a new collection helper.  Should take the following named arguments:
C<moniker> (interpreted by L<JFDI::View::Helper>) and C<collection>, a L<JFDI::Collection>
which is to be displayed.  

The collection should already have had some limits set on it (or C<un_limit>).

=cut

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  my %args = (
    collection => undef,
    @_
  ); 
  
  $self->collection($args{'collection'});

  return $self;
}

=head2 collection [VALUE]

Gets or sets the L<JFDI::Collection> that this view helper controls.

=cut

__PACKAGE__->mk_accessors(qw(collection));

=head2 render_as_list

Renders the elements of the collection on the current page (determined by the 
state variable C<current_page>). Takes the following
arguments:

=over 4

=item rows_per_page

The number of rows per page.  Defaults to 20.

=item item_renderer

A L<JFDI::Callback>, which takes arguments "item" and "collection".  This item should
render a single item from the collection.  By default, renders a C<LI> element containing
the item's C<id> and C<name>.

=item next_page, previous_page

L<JFDI::Callback>s which render Next Page and Previous Page links.  They take a
>"query_args"
argument, which if appended to an URL should create a link to the next or previous page.
By default, create a link to the current component's path called "Next Page" or "Previous Page".

=item status_info

A L<JFDI::Callback> which takes the following arguments: 
total_entries entries_per_page current_page entries_on_this_page first_page last_page first last previous_page next_page, and skipped.  See L<Data::Page> for their definitions.  You can use this to display messages like
"Page 2 of 3".  By default, displays nothing.

=item none_found

A L<JFDI::Callback> which is called if the collection is empty.

=back

=cut

sub render_as_list {
    my $self = shift;
    my %args = (
        rows_per_page => 20,
        item_renderer => JFDI::Callback::ComponentSource->new(
            q{<%args>$item</%args><li> <%$item->id%> <% $item->name()%></li> }),
        next_page => JFDI::Callback::ComponentSource->new(q{<%args>$query_args</%args>
            <span class="next-page"><a href="<% $m->{top_path} %>?<% $query_args %>#content">Next Page</a></span>
            }),
        previous_page => JFDI::Callback::ComponentSource->new(q{<%args>$query_args</%args>
            <span class="prev-page"><a href="<% $m->{top_path} %>?<% $query_args %>#content">Previous Page</a></span>
            }),
        status_info => undef,
        none_found => JFDI::Callback::String->new("No items found."),
        @_
    );

    $self->collection->set_page_info(
        current_page =>
          $self->state('current_page') || 1,
        per_page => $args{'rows_per_page'},
    );

    if ($self->collection->pager->total_entries == 0) {
        $args{'none_found'}->call;
        return;
    } 

    if ( defined $args{'status_info'} ) {
        my %status_info_args = ();

        # All of the methods of Data::Page except for splice
        foreach my $arg
          qw(total_entries entries_per_page current_page entries_on_this_page first_page last_page first last previous_page next_page skipped)
        {

            $status_info_args{$arg} = $self->collection->pager->$arg();

        }

        $args{'status_info'}->call( %status_info_args );
    }

    while ( my $item = $self->collection->next() ) {
        $args{'item_renderer'}->call(
            item       => $item,
            collection => $self->collection,
        );
    }

    # Navigation
    foreach my $direction qw(previous_page next_page) {

        # Navigation
        $args{$direction}->call(
            query_args => JFDI->framework->query_string(JFDI->framework->request->clone->add_helper(
                moniker => $self->moniker,
                class => ref($self),
                states => { current_page => $self->collection->pager->$direction() },
            )->helpers_as_query_args),
          )
          if defined $self->collection->pager->$direction();
    }
}

1;
