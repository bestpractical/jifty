use warnings;
use strict;

package Jifty::View::Declare::CRUD;
use Jifty::View::Declare -base;
use base 'Exporter';
our @EXPORT = qw(object_type fragment_for get_record current_collection);

sub object_type {
    my $self = shift;
    return $self->package_variable('object_type') || get('object_type');
}

sub fragment_for {
    my $self     = shift;
    my $fragment = shift;

    if ( my $coderef = $self->can( 'fragment_for_' . $fragment ) ) {
        return $coderef->($self);
    }

    return $self->package_variable( 'fragment_for_' . $fragment )
        || $self->fragment_base_path . "/" . $fragment;
}

sub fragment_base_path {
    my $self = shift;
    return $self->package_variable('base_path') || '/crud';
}

sub get_record {
    my ( $self, $id ) = @_;

    my $record_class = Jifty->app_class( "Model", $self->object_type );
    my $record = $record_class->new();
    $record->load($id);

    return $record;
}

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

template 'view' => sub {
    my $self = shift;
    my ( $object_type, $id ) = ( $self->object_type, get('id') );
    my $update = new_action(
        class   => 'Update' . $object_type,
        moniker => "update-" . Jifty->web->serial,
        record  => $self->get_record($id)
    );

    div {
        { class is 'crud read item inline' };
        hyperlink(
            label   => "Edit",
            class   => "editlink",
            onclick => {
                replace_with => $self->fragment_for('update'),
                args         => { object_type => $object_type, id => $id }
            },
        );

        my @fields = grep {
            !( m/_confirm/
                || lc $update->arguments->{$_}{render_as} eq 'password' )
        } $update->argument_names;
        render_action( $update, \@fields, { render_mode => 'read' } );
        hr {};
    };

};

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
                as_button => 1
            );
        };

        render_action($update);
        hr {};
        }
};


sub current_collection {
    my $self =shift; 
    my ( $page, $search_collection ) = get(qw(page  search_collection));

    my $collection_class = Jifty->app_class( "Model", $self->object_type . "Collection" );
    my $search = $search_collection || Jifty->web->response->result('search');
    my $collection;
    if ( !$search ) {
        $collection = $collection_class->new();
        $collection->unlimit();
    } else {
        $collection = $search->content('search');
    }

    $collection->set_page_info( current_page => $page, per_page => 25 );

    return $collection;    
}

template 'list' => sub {
    my $self = shift;

    my ( $page, $search_collection ) = get(qw(page  search_collection));
    my $fragment_for_new_item = get('fragment_for_new_item') || $self->fragment_for('new_item');
    my $item_path = get('item_path') || $self->fragment_for("view");

    my $collection =  $self->current_collection();
    show('./search_region');
    show( './paging_top',    $collection, $page );
    show( './list_items',    $collection, $item_path );
    show( './paging_bottom', $collection, $page );
    show( './new_item_region', $fragment_for_new_item );

};

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
private template 'new_item_region' => sub {
    my $self        = shift;
    my $fragment_for_new_item = shift;
    my $object_type = $self->object_type;

    if ($fragment_for_new_item) {
        render_region(
            name     => 'new_item',
            path     => $fragment_for_new_item,
            defaults => { object_type => $object_type },
        );
    }
};

private template 'list_items' => sub {
    my $self        = shift;
    my $collection  = shift;
    my $item_path   = shift;
    my $object_type = $self->object_type;
    if ( $collection->pager->total_entries == 0 ) {
        outs( _("No items found") );
    }

    div {
        { class is 'list' };
        while ( my $item = $collection->next ) {
            render_region(
                name     => 'item-' . $item->id,
                path     => $item_path,
                defaults => { id => $item->id, object_type => $object_type }
            );
        }
    };

};

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
                    label   => "Previous Page",
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
                    label   => "Next Page",
                    onclick =>
                        { args => { page => $collection->pager->next_page } }
                );
                }
        }
    };
};

template 'new_item' => sub {
    my $self = shift;
    my ( $object_type, $id ) = ( $self->object_type, get('id') );

    my $record_class = Jifty->app_class( "Model", $object_type );
    my $create = Jifty->web->new_action( class => 'Create' . $object_type );

    div {
        { class is 'crud create item inline' };
        render_action($create);

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

1;

