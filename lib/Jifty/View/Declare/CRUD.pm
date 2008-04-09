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

=head1 SYNOPSIS

  package App::View::User;
  use Jifty::View::Declare -base;
  use base qw/ Jifty::View::Declare::CRUD /;

  template 'view' => sub {
      # customize the view
  };

  1;

  package App::View::Tag;
  use Jifty::View::Declare -base;
  use base qw/ Jifty::View::Declare::CRUD /;

  template 'view' => sub {
      # customize the view
  };

  1;

  package App::View;
  use Jifty::View::Declare -base;

  use Jifty::View::Declare::CRUD;

  # If you have customizations, this is a good way...
  Jifty::View::Declare::CRUD->mount_view('User');
  Jifty::View::Declare::CRUD->mount_view('Category', 'App::View::Tag', '/tag');

  # Another way to do the above, good for quick and dirty
  alias Jifty::View::Declare::CRUD under '/admin/blog', {
      object_type => 'BlogPost',
  };

=head1 DESCRIPTION

This class provides a set of views that may be used by a model to display
Create/Read/Update/Delete views using the L<Template::Declare> templating
language.

Basically, you can use this class to do most (and maybe all) of the work you need to manipulate and view your records.

=head1 METHODS

=begin pod_coverage

=head2 CRUDView

=end pod_coverage

=head2 mount_view MODELCASS VIEWCLASS /path

Call this method in your appliation's view class to add the CRUD views you're looking for. Only the first argument is required.

Arguments:

=over

=item MODELCLASS

This is the name of the model that you want to generate the CRUD views for. This is the only required parameter. Leave off the parts of the class name prior to and including the "Model" part. (I.e., C<App::Model::User> should be passed as just C<User>).

=item VIEWCLASS

This is the name of the class that will be generated to hold the CRUD views of your model. If not given, it will be set to: C<App::View::I<MODELCLASS>>. If given, it should be the full name of the view class.

=item /path

This is the path where you can reach the CRUD views for this model in your browser. If not given, this will be set to the model class name in lowercase letters. (I.e., C<User> would be found at C</user> if not passed explicitly).

=back

=cut

sub mount_view {
    my ($class, $model, $vclass, $path) = @_;
    my $caller = caller(0);

    # Sanitize the arguments
    $model = ucfirst($model);
    $vclass ||= $caller.'::'.$model;
    $path ||= '/'.lc($model);

    # Load the view class, alias it, and define its object_type method
    Jifty::Util->require($vclass);
    eval qq{package $caller;
            alias $vclass under '$path'; 1} or die $@;

    # Override object_type
    no strict 'refs';
    my $object_type = $vclass."::object_type";

    # Avoid the override if object_type() is already defined
    *{$object_type} = sub { $model } unless defined *{$object_type};
}

# XXX TODO FIXME This is related to the trimclient branch and performs some
# magic related to that or that was once related to that. This is also related
# to the CRUDView attribute above. This is a little unfinished, but I'll leave
# it up to clkao to figure out what needs to happen here.
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

This method returns the type of object this CRUD view has been generated for. This is normally the model class parameter that was passed to L</mount_view>.

=cut

sub object_type {
    my $self = shift;
    return $self->package_variable('object_type') || get('object_type');
}

=head2 record_class

This is the full name of the model class these CRUD views are for. The default implementation returns:

  Jifty->app_class('Model', $self->object_type);

You will want to override this if (in addition to L</object_type>) if you want to provide CRUD views in a plugin, or from an external model class, or for one of the Jifty built-in models.

=cut

# NB: We don't just create the record class here and return it. Why? Because
# the mount_view() method is generally called very early in the Jifty
# lifecycle. As such, Jifty->app_class() might not work yet since it requires
# the Jifty singleton to be built and the configuration to be loaded. So, this
# implementation caches teh record class after the first calculation, which
# should happen during the request dispatch process, which always happens after
# Jifty is completely initialized.
sub record_class {
    my $self = shift;

    # If object_type is set via set, don't cache
    if (!$self->package_variable('object_type') && get('object_type')) {
        return Jifty->app_class('Model', $self->object_type);
    }

    # Otherwise, assume object_type is permanent
    else {
        return ($self->package_variable('record_class') 
            or ($self->package_variable( record_class =>
                    Jifty->app_class('Model', $self->object_type))));
    }

}

=head2 fragment_for

This is a helper that returns the path to a given fragment. The only argument is the name of the fragment. It returns a absolute base path to the fragment page.

This will attempt to lookup a method named C<fragment_for_I<FRAGMENT>>, where I<FRAGMENT> is the argument passed. If that method exists, it's result is used as the returned path.

Otherwise, the L</fragment_base_path> is joined to the passed fragment name to create the return value.

If you really want to mess with this, you may need to read the source code of this class.

=cut

sub fragment_for {
    my $self     = shift;
    my $fragment = shift;

    # Check for fragment_for_$fragment and use that if it exists
    if ( my $coderef = $self->can( 'fragment_for_' . $fragment ) ) {
        return $coderef->($self);
    }

    # Otherwise return the fragment_base_path/$fragment
    return $self->package_variable( 'fragment_for_' . $fragment )
        || $self->fragment_base_path . "/" . $fragment;
}

=head2 fragment_base_path

This is a helper for L</fragment_for>. It looks up the current template using L<Template::Declare::Tags/current_template>, finds it's parent path and then returns that.

If you really want to mess with this, you may need to read the source code of this class.

=cut

sub fragment_base_path {
    my $self = shift;

    # Rip it apart
    my @parts = split('/', current_template());

    # Remove the last element
    pop @parts;

    # Put it back together again
    my $path = join('/', @parts);

    # And serve
    return $path;
}

=head2 _get_record $id

Given an $id, returns a record object for the CRUD view's model class.

=cut

sub _get_record {
    my ( $self, $id ) = @_;

    # Load the model, create an empty object, load the object by ID
    my $record_class = $self->record_class;
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
     return   $action->argument_names;
     #return   grep { !( m/_confirm/ ||  $action->arguments->{$_}{unreadable} ) } $action->argument_names;
}


sub edit_columns {
    my $self = shift; 
    return $self->display_columns(@_);
}

sub create_columns {
    my $self = shift; 
    return $self->edit_columns(@_);


}



=head1 TEMPLATES

=head2 index.html

Contains the master form and page region containing the list of items. This is mainly a wrapper for the L</list> fragment.

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

The search fragment displays a search screen connected to the search action of the module. 

See L<Jifty::Action::Record::Search>.

=cut

template 'search' => sub {
    my $self          = shift;
    my ($object_type) = ( $self->object_type );
    my $search        = $self->record_class->as_search_action(
        moniker           => 'search',
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

This fragment displays the data held by a single model record.

=cut

template 'view' => sub :CRUDView {
    my $self   = shift;
    my $record = $self->_get_record( get('id') );

    my $update = $record->as_update_action(
        moniker => "update-" . Jifty->web->serial,
    );

    div {
        { class is 'crud read item inline' };
        my @fields = $self->display_columns($update);
        foreach my $field (@fields) {
            div { { class is 'view-argument-'.$field};
            render_param( $update => $field,  render_mode => 'read'  );
            }; 
        }
        show ('./view_item_controls', $record, $update); 
    };
    hr {};

};

=head2 private template view_item_controls

Used by the view fragment to show the edit link for each record.

=cut

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

The update fragment displays a form for editing the data held within a single model record. 

See L<Jifty::Action::Record::Update>.

=cut

template 'update' => sub {
    my $self = shift;
    my ( $object_type, $id ) = ( $self->object_type, get('id') );

    my $record_class = $self->record_class;
    my $record = $record_class->new();
    $record->load($id);
    my $update = $record->as_update_action(
        moniker => "update-" . Jifty->web->serial,
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

    my $delete = $record->as_delete_action(
        moniker => 'delete-' . Jifty->web->serial,
    );
        div {
            { class is 'crud editlink' };
            hyperlink(
                label   => _("Save"),
                onclick => [
                    { submit => $update },
                    {   replace_with => $self->fragment_for('view'),
                        args => { object_type => $object_type, id => $id }
                    }
                ]
            );
            hyperlink(
                label   => _("Cancel"),
                onclick => {
                    replace_with => $self->fragment_for('view'),
                    args         => { object_type => $object_type, id => $id }
                },
                as_button => 1,
                class     => 'cancel'
            );
            if ( $record->current_user_can('delete') ) {
                $delete->button(
                    label   => _('Delete'),
                    onclick => {
                        submit  => $delete,
                        confirm => _('Really delete?'),
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

    my ( $page ) = get('page');
    my $item_path = get('item_path') || $self->fragment_for("view");
    my $collection =  $self->_current_collection();
    div { {class is 'crud-'.$self->object_type}; 

    show('./search_region');
    show( './paging_top',    $collection, $page );
    show( './list_items',    $collection, $item_path );
    show( './paging_bottom', $collection, $page );
    show( './new_item_region');
    };
};

=head2 per_page

This routine returns how many items should be shown on each page of a listing.
The default is 25.

=cut

sub per_page { 25 }

# This method just does a whole lot of sanitizing to try and get a valid
# collection out the other end based upon either the current search or an
# unlimited collection if there is no current search.
sub _current_collection {
    my $self = shift; 
    my ( $page ) = get('page');
    my $collection_class = $self->record_class->collection_class;
    my $search = ( Jifty->web->response->result('search') ? Jifty->web->response->result('search')->content('search') : undef );
    my $collection;
    if ( $search ) {
        $collection = $search;
    } else {
        $collection = $collection_class->new();
        $collection->find_all_rows();
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
        label => _('Toggle search'),
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
            defaults => {
                        object_type => $object_type },
        );
    }
};

=head2 no_items_found

Prints "No items found."

=cut

private template 'no_items_found' => sub {
    div {
        { class is 'no_items' };
        outs( _("No items found.") );
    }
};

=head2 list_items $collection $item_path

Renders a div of class list with a region per item.

=cut

private template 'list_items' => sub {
    my $self        = shift;
    my $collection  = shift;
    my $item_path   = shift;
    my $callback    = shift;
    my $object_type = $self->object_type;
    $collection->_do_search(); # we're going to need the results. 
    # XXX TODO, should use a real API to force the search
    if ( $collection->count == 0 ) {
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
    my $page       = shift || 1;

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


=head2 create_item $action

Renders the action $Action, handing it the array ref returned by L</display_columns>.

=cut

private template 'create_item' => sub {
    my $self = shift;
    my $action = shift;
   foreach my $field ($self->create_columns($action)) {
            div { { class is 'create-argument-'.$field}
                render_param($action, $field) ;
        }
   }
};

=head2 edit_item $action

Renders the action $Action, handing it the array ref returned by L</display_columns>.

=cut

private template 'edit_item' => sub {
    my $self = shift;
    my $action = shift;
   foreach my $field ($self->edit_columns($action)) {
            div { { class is 'update-argument-'.$field}
    render_param($action, $field) ;
        }
   }
};

=head1 new_item

The new_item template provides a form for creating new model records. See L<Jifty::Action::Record::Create>.

=cut

template 'new_item' => sub {
    my $self = shift;
    my ( $object_type ) = ( $self->object_type );

    my $record_class = $self->record_class;
    my $create = $record_class->as_create_action;

    div {
        { class is 'crud create item inline' };
        show('./create_item', $create);
        show('./new_item_controls', $create);
    }
};

private template 'new_item_controls' => sub {
        my $self = shift;
        my $create = shift;
    my ( $object_type ) = ( $self->object_type);

        outs(
            Jifty->web->form->submit(
                label   => _('Create'),
                onclick => [
                    { submit       => $create },
                    { refresh_self => 1 },
                    {   element => Jifty->web->current_region->parent->get_element( 'div.list'),
                        append => $self->fragment_for('view'),
                        args   => {
                            object_type => $object_type,
                            id => { result_of => $create, name => 'id' },
                        },
                    },
                ]
            )
        )
    };




=head1 SEE ALSO

L<Jifty::Action::Record::Create>, L<Jifty::Action::Record::Search>, L<Jifty::Action::Record::Update>, L<Jifty::Action::Record::Delete>, L<Template::Declare>, L<Jifty::View::Declare::Helpers>, L<Jifty::View::Declare>

=head1 LICENSE

Jifty is Copyright 2005-2007 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;

