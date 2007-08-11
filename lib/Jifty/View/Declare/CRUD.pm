use warnings;
use strict;

package Jifty::View::Declare::CRUD;
use Jifty::View::Declare -base;

# XXX: should register 'template type' handler, so the
# client_cache_content & the TD sub here agrees with the arguments.
use Attribute::Handlers;
my %VIEW;
sub CRUDView :ATTR(CODE,BEGIN) {
    $VIEW{$_[2]}++;
}


=head1 NAME

Jifty::View::Declare::CRUD - Provides typical CRUD views to a model

=head1 DESCRIPTION

This class provides a set of views that may be used by a model to
display Create/Read/Update/Delete views using the L<Template::Declare>
templating language.

=head1 METHODS

=cut


=head2 mount_view MODELCASS VIEWCLASS /path

=cut

sub mount_view {
    my ($class, $model, $vclass, $path) = @_;
    my $caller = caller(0);
    $model = ucfirst($model);
    $vclass ||= $caller.'::'.$model;
    $path ||= '/'.lc($model);

    Jifty::Util->require($vclass);
    eval qq{package $caller;
            alias $vclass under '$path'; 1} or die $@;
    no strict 'refs';
    *{$vclass."::object_type"} = sub { $model };
}

sub _dispatch_template {
    my $class = shift;
    my $code  = shift;
    if ($VIEW{$code} && !UNIVERSAL::isa($_[0], 'Evil')) {
	my ( $object_type, $id ) = ( $class->object_type, get('id') );
	@_ = ($class, $class->_get_record($id), @_);
    }
    else {
	unshift @_, $class;
    }
    goto $code;
}


=head2 object_type

=cut

sub object_type {
    my $self = shift;
    return $self->package_variable('object_type') || get('object_type');
}


=head2 fragment_for

=cut

sub fragment_for {
    my $self     = shift;
    my $fragment = shift;

    if ( my $coderef = $self->can( 'fragment_for_' . $fragment ) ) {
        return $coderef->($self);
    }

    return $self->package_variable( 'fragment_for_' . $fragment )
        || $self->fragment_base_path . "/" . $fragment;
}

=head2 fragment_base_path

=cut

sub fragment_base_path {
    my $self = shift;
    my @parts = split('/', current_template());
    pop @parts;
    my $path = join('/', @parts);
    return $path;
}

=head2 _get_record $id

Given an $id, returns a record object for the CRUD view's model class.

=cut

sub _get_record {
    my ( $self, $id ) = @_;

    my $record_class = Jifty->app_class( "Model", $self->object_type );
    my $record = $record_class->new();
    $record->load($id);

    return $record;
}

=head2 display_columns

Returns a list of all the columns that this REST view should display

=cut

sub display_columns {
    my $self = shift;
    my $action = shift;
     return   grep { !( m/_confirm/ || lc $action->arguments->{$_}{render_as} eq 'password' ) } $action->argument_names;
}


=head1 TEMPLATES


=cut

=head2 index.html


=cut


template 'index.html' => page {
    my $self = shift;
    title is $self->object_type;
    form {
            render_region(
                name     => $self->object_type.'-list',
                path     => $self->fragment_base_path.'/list');
    }

};

 



=head2 search

The search view displays a search screen connected to the search action of the module. See L<Jifty::Action::Record::Search>.

=cut

template 'search' => sub {
    my $self          = shift;
    my ($object_type) = ( $self->object_type );
    my $search        = Jifty->web->new_action(
        class             => "Search" . $object_type,
        moniker           => "search",
        sticky_on_success => 1,
    );

    div {
        { class is "jifty_admin" };
        render_action($search);

        $search->button(
            label   => _('Search'),
            onclick => {
                submit  => $search,
                refresh => Jifty->web->current_region->parent,
                args    => { page => 1 }
            }
        );

        }
};

=head2 view

This template displays the data held by a single model record.

=cut

template 'view' => sub :CRUDView {
    my $self   = shift;
    my $record = $self->_get_record( get('id') );

    my $update = new_action(
        class   => 'Update' . $self->object_type,
        moniker => "update-" . Jifty->web->serial,
        record  => $record,
    );

    div {
        { class is 'crud read item inline' };
        my @fields = $self->display_columns($update);
        render_action( $update, \@fields, { render_mode => 'read' } );

        show ('./view_item_controls', $record, $update); 

        hr {};
    };

};

private template view_item_controls  => sub {
    my $self = shift;
    my $record = shift;

    if ( $record->current_user_can('update') ) {
        hyperlink(
            label   => _("Edit"),
            class   => "editlink",
            onclick => {
                replace_with => $self->fragment_for('update'),
                args         => { id => $record->id }
            },
        );
    }
};



=head2 update

The update template displays a form for editing the data held within a single model record. See L<Jifty::Action::Record::Update>.

=cut

template 'update' => sub {
    my $self = shift;
    my ( $object_type, $id ) = ( $self->object_type, get('id') );

    my $record_class = Jifty->app_class( "Model", $object_type );
    my $record = $record_class->new();
    $record->load($id);
    my $update = new_action(
        class   => "Update" . $object_type,
        moniker => "update-" . Jifty->web->serial,
        record  => $record
    );

    div {
        { class is "crud update item inline " . $object_type }

        show('./edit_item', $update);
        show('./edit_item_controls', $record, $update);

        hr {};
        }
};



=head2 edit_item_controls $record $action

The controls we should be rendering in the 'edit' region for a given fragment

=cut

private template edit_item_controls => sub {
    my $self = shift;
    my $record = shift;
    my $update = shift;

    my $object_type = $self->object_type;
    my $id = $record->id;

    my $delete = Jifty->web->form->add_action(
        class   => 'Delete' . $object_type,
        moniker => 'delete-' . Jifty->web->serial,
        record  => $record
    );

        div {
            { class is 'crud editlink' };
            hyperlink(
                label   => "Save",
                onclick => [
                    { submit => $update },
                    {   replace_with => $self->fragment_for('view'),
                        args => { object_type => $object_type, id => $id }
                    }
                ]
            );
            hyperlink(
                label   => "Cancel",
                onclick => {
                    replace_with => $self->fragment_for('view'),
                    args         => { object_type => $object_type, id => $id }
                },
                as_button => 1,
                class => 'cancel'
            );
            if ( $record->current_user_can('delete') ) {
                $delete->button(
                    label   => 'Delete',
                    onclick => {
                        submit => $delete,
                        confirm => 'Really delete?',
                        refresh => Jifty->web->current_region->parent,
                    },
                    class => 'delete'
                );
            }
        };

};

=head2 list

The list template provides an interactive list for showing a list of records in the record collection, adding new records, deleting records, and updating records.

=cut

template 'list' => sub {
    my $self = shift;

    my ( $page ) = get(qw(page ));
    my $item_path = get('item_path') || $self->fragment_for("view");
    my $collection =  $self->_current_collection();

    show('./search_region');
    show( './paging_top',    $collection, $page );
    show( './list_items',    $collection, $item_path );
    show( './paging_bottom', $collection, $page );
    show( './new_item_region');

};

=head2 per_page

This routine returns how many items should be shown on each page of a listing.
The default is 25.

=cut

sub per_page { 25 }

sub _current_collection {
    my $self =shift; 
    my ( $page, $search_collection ) = get(qw(page  search_collection));
    my $collection_class = Jifty->app_class( "Model", $self->object_type . "Collection" );
    my $search = $search_collection || ( Jifty->web->response->result('search') ? Jifty->web->response->result('search')->content('search') : undef );
    my $collection;
    if ( $search ) {
        $collection = $search;
    } else {
        $collection = $collection_class->new();
        $collection->unlimit();
    }

    $collection->set_page_info( current_page => $page, per_page => $self->per_page );

    return $collection;    
}


=head2 search_region

This I<private> template renders a region to show an expandable region for a search widget.

=cut

private template 'search_region' => sub {
    my $self        = shift;
    my $object_type = $self->object_type;

    my $search_region = Jifty::Web::PageRegion->new(
        name => 'search',
        path => '/__jifty/empty'
    );

    hyperlink(
        onclick => [
            {   region       => $search_region->qualified_name,
                replace_with => $self->fragment_for('search'),
                toggle       => 1,
                args         => { object_type => $object_type }
            },
        ],
        label => 'Toggle search'
    );

    outs( $search_region->render );
};

=head2 new_item_region

This I<private> template renders a region to show a the C<new_item> template.

=cut


private template 'new_item_region' => sub {
    my $self        = shift;
    my $fragment_for_new_item = get('fragment_for_new_item') || $self->fragment_for('new_item');
    my $object_type = $self->object_type;

    if ($fragment_for_new_item) {
        render_region(
            name     => 'new_item',
            path     => $fragment_for_new_item,
            defaults => { object_type => $object_type },
        );
    }
};


=head2 list_items $collection $item_path

Renders a div of class list with a region per item.



=cut

private template 'no_items_found' => sub { outs(_("No items found.")) };

private template 'list_items' => sub {
    my $self        = shift;
    my $collection  = shift;
    my $item_path   = shift;
    my $callback    = shift;
    my $object_type = $self->object_type;
    if ( $collection->pager->total_entries == 0 ) {
        show('./no_items_found');
    }

    my $i = 0;
    div {
        { class is 'list' };
        while ( my $item = $collection->next ) {
            render_region(
                name     => 'item-' . $item->id,
                path     => $item_path,
                defaults => { id => $item->id, object_type => $object_type }
            );
            $callback->(++$i) if $callback;
        }
    };

};


=head2 paging_top $collection $page_number

Paging for your list, rendered at the top of the list

=cut


private template 'paging_top' => sub {
    my $self       = shift;
    my $collection = shift;
    my $page       = shift;

    if ( $collection->pager->last_page > 1 ) {
        span {
            { class is 'page-count' };
            outs(
                _( "Page %1 of %2", $page, $collection->pager->last_page ) );
            }
    }

};

=head2 paging_bottom $collection $page_number

Paging for your list, rendered at the bottom of the list

=cut

private template paging_bottom => sub {
    my $self       = shift;
    my $collection = shift;
    my $page       = shift;
    div {
        { class is 'paging' };
        if ( $collection->pager->previous_page ) {
            span {
                { class is 'prev-page' };
                hyperlink(
                    label   => _("Previous Page"),
                    onclick => {
                        args => { page => $collection->pager->previous_page }
                    }
                );
                }
        }
        if ( $collection->pager->next_page ) {
            span {
                { class is 'next-page' };
                hyperlink(
                    label   => _("Next Page"),
                    onclick =>
                        { args => { page => $collection->pager->next_page } }
                );
                }
        }
    };
};



=head2 edit_item $action

Renders the action $Action, handing it the array ref returned by L</display_columns>.

=cut



private template 'edit_item' => sub {
    my $self = shift;
    my $action = shift;
    render_action($action, [$self->display_columns($action)]);
};

=head1 new_item

The new_item template provides a form for creating new model records. See L<Jifty::Action::Record::Create>.

=cut

template 'new_item' => sub {
    my $self = shift;
    my ( $object_type, $id ) = ( $self->object_type, get('id') );

    my $record_class = Jifty->app_class( "Model", $object_type );
    my $create = Jifty->web->new_action( class => 'Create' . $object_type );

    div {
        { class is 'crud create item inline' };
        show('./edit_item', $create);

        outs(
            Jifty->web->form->submit(
                label   => 'Create',
                onclick => [
                    { submit       => $create },
                    { refresh_self => 1 },
                    {   element =>
                            Jifty->web->current_region->parent->get_element(
                            'div.list'),
                        append => $self->fragment_for('view'),
                        args   => {
                            object_type => $object_type,
                            id => { result_of => $create, name => 'id' },
                        },
                    },
                ]
            )
        );
        }
};

=head1 SEE ALSO

L<Jifty::Action::Record::Create>, L<Jifty::Action::Record::Search>, L<Jifty::Action::Record::Update>, L<Jifty::Action::Record::Delete>, L<Template::Declare>, L<Jifty::View::Declare::Helpers>, L<Jifty::View::Declare>

=head1 LICENSE

Jifty is Copyright 2005-2007 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;

