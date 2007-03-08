package Jifty::Plugin::AdminUI::View;

use strict;
use warnings;

use Jifty::View::Declare -base;

use Scalar::Defer;

=head1 NAME

Jifty::Plugin::AdminUI::View

=head1 DESCRIPTION

Work In progress. Needs more factoring, tests, etc

=cut

template '__jifty/admin/_elements/nav' => sub {
    my $nav =
      Jifty->web->navigation->child(
        "Administration" => url => '/__jifty/admin/' );
    foreach my $model ( Jifty->class_loader->models ) {
        next unless $model->isa('Jifty::Record');
        next unless ( $model =~ /^(?:.*)::(.*?)$/ );
        my $type = $1;
        $nav->child( $type => url => '/__jifty/admin/model/' . $type );
    }
    return;
};

template '__jifty/admin/action/dhandler' => sub {
    # XXX move to dispatcher
    my $action_class = Jifty->api->qualify( die('$m->dhandler_arg') );

    my $object_type = die "No object type defined";

    my $action = new_action(
        class   => $action_class,
        moniker => "run-$action_class",
    );

    $action->sticky_on_failure(1);
    page {
        title is { _('Manage records: [_1]',$object_type) };
        form {

            for ( $action->argument_names ) {
                render_param( $action, $_ );
            }

            Jifty->web->form->submit( label => _("Run the action") );
        };

        h2 { _('Done?') };
        hyperlink(
            url   => "/__jifty/admin/",
            label => _('Back to the admin console')
        );

      }
};

template '__jifty/admin/autohandler' => sub {

# If "AdminMode" is turned off in Jifty's config file, don't let people at the admin UI.
    unless ( Jifty->config->framework('AdminMode') ) {
        redirect('/__jifty/error/permission_denied');
        return;
    }
    show('/__jifty/admin/elements/nav'); # XXX TODO hm. should be in dispatcher.
};

template '__jifty/admin/fragments/list/list' => sub {
    my ( $object_type, $page, $new_slot, $item_path, $list_path, $limit_field, $limit_val, $per_page, $sort_by, $order, $search_slot ) =
      get(qw( object_type page new_slot item_path list_path limit_field limit_val per_page sort_by order search_slot));

    $page ||= 1;
    $new_slot = 1 unless defined $new_slot;
    $item_path ||= "/__jifty/admin/fragments/list/view";
    $list_path ||= "/__jifty/admin/fragments/list";
    $per_page ||=25;
    $search_slot ||=1; 



    my $collection_class =
      Jifty->app_class( "Model", $object_type . "Collection" );
    my $search = Jifty->web->response->result('search');
    my $collection  = $collection_class->new();
;
    if ( !$search ) {
   if ( $limit_field && $limit_val ) {
      $collection->limit(column => $limit_field, value => $limit_val);
   } else {
      $collection->unlimit();
   }
   $collection->order_by(column => $sort_by, order=>'ASC') if ($sort_by && !$order);
   $collection->order_by(column => $sort_by, order=>'DESC') if ($sort_by && $order);
    }
    else {
        $collection = $search->content('search');
        warn $collection->build_select_query;
    }

    $collection->set_page_info(
        current_page => $page,
        per_page     => $per_page
    );

if ($search_slot) {
    my $search_region = Jifty::Web::PageRegion->new(
        name => 'search',
        path => '/__jifty/empty',
    );

    hyperlink(
        onclick => [
            {
                region       => $search_region->qualified_name,
                replace_with => $list_path. 'search',
                toggle       => 1,
                args         => { object_type => $object_type }
            },
        ],
        label => _('Toggle search')
    );

    $search_region->render;
}
    if ( $collection->pager->last_page > 1 ) {
        with( class => "page-count" ), span {
            _( 'Page %1 of %2', $page, $collection->pager->last_page );
          }
    }

    if ( $collection->pager->total_entries == 0 ) {
        outs(_('No items found'));
    } else {
        outs(_('%1 entries', $collection-> count));
        show( $list_path.'header', object_type => $object_type, list_path => $list_path, 
    mask_field => $limit_field, mask_val => $limit_val, sort_by => $sort_by, order => $order);
    }

    with( class => "list" ), div {
        while ( my $item = $collection->next ) {
            Jifty->web->region(
                name     => 'item-' . $item->id,
                path     => $item_path,
                defaults => { id => $item->id, object_type => $object_type,
list_path => $list_path, mask_field => $limit_field , mask_val => $limit_val 
 }
            );
        }

    };

    with( class => "paging" ), div {
        if ( $collection->pager->previous_page ) {
            with( class => "prev-page" ), span {
                hyperlink(
                    label   => _("Previous Page"),
                    onclick =>
                      { args => { page => $collection->pager->previous_page } }
                );
              }
        }
        if ( $collection->pager->next_page ) {
            with( class => "next-page" ), span {
                hyperlink(
                    label   => _("Next Page"),
                    onclick =>
                      { args => { page => $collection->pager->next_page } }
                );
              }
        }
    };

    if ($new_slot) {
        Jifty->web->region(
            name     => 'new_item',
        path => $list_path.'new_item',
        defaults => {   object_type => $object_type, list_path => $list_path,
                     mask_field => $limit_field , mask_val => $limit_val },
        );
    }

};

# When you hit "save" and create a item, you want to put a fragment
# containing the new item in the associated list and refresh the current
# fragment
#
template '__jifty/admin/fragments/list/new_item' => sub {
    my ( $object_type, $region, $mask_field, $mask_val, $list_path ) = get(qw(object_type region mask_field mask_val list_path));
    my $record_class = Jifty->app_class( "Model", $object_type );
    my $create = new_action( class => 'Create' . $object_type );
    if ($mask_field) {
        $create->hidden($mask_field,$mask_val);
        }

    div {
    attr{ class => "jifty_admin create item inline" };
        foreach my $argument ( $create->argument_names ) {
            if ( $argument ne $mask_field ) {
            render_param( $create => $argument );
        }
        }
    };

    Jifty->web->form->submit(
        label   => _('Create'),
        onclick => [
            { submit       => $create },
            { refresh_self => 1 },
            {
                element => $region->parent->get_element('div.list'),
                append  => $list_path.'view',
                args    => {
                    object_type => $object_type,
                    list_path => $list_path,
                    id          => { result_of => $create, name => 'id' },
                },
            },
        ]
      )

};

template '__jifty/admin/fragments/list/header' => sub {
my ($object_type, $mask_val , $mask_field, $sort_by, $order, $list_path) =
get(qw(object_type mask_val mask_field sort_by order list_path));
my $record_class = Jifty->app_class("Model", $object_type);
my $record = $record_class->new();
 my $update = Jifty->web->new_action(class => 'Update'.$object_type);
div {
attr { class=>"jifty_admin_header" };

 foreach my $argument ($update->argument_names) {
 unless( $argument eq $mask_field ||  $argument eq 'id' || $argument =~ /_confirm$/i
        && lc $update->arguments->{$argument}{render_as} eq 'password') {
span { attr {class=>"<% ($sort_by && !$order && $sort_by eq $argument)?'up_select':'up' %>"};

    hyperlink(
        label   => _("asc"),
        onclick => 
            { 
            replace_with => $list_path.'list' ,
            args   => {
                object_type => $object_type,
                limit_val => $mask_val,
                limit_field => $mask_field,
                list_path => $list_path,
                sort_by => $argument,
                order => undef
                },
            },
        #as_button => 1
        );
}
span { attr{ class=>"<% ($sort_by && $order && $sort_by eq $argument )?'down_select':'down' %>" };
    hyperlink(
        label   => _("desc"),
        onclick => 
            {
            replace_with => $list_path.'list',
            args   => {
                object_type => $object_type,
                limit_val => $mask_val,
                limit_field => $mask_field,
                list_path => $list_path,
                sort_by => $argument,
                order => 'D'
                },
            },
        #as_button => 1
        )
}
span { attr { class=>"field" };
    outs ($argument );
}
 }
 }
hr {};
}
};


template '__jifty/admin/fragments/list/search' => sub {
    my ($object_type) = get(qw(object_type));
    my $search = new_action(
        class             => "Search" . $object_type,
        moniker           => "search",
        sticky_on_success => 1,
    );

    with( class => "jifty_admin" ), div {
        for my $arg ( $search->argument_names ) {
            render_param( $search => $arg );
        }

        $search->button(
            label   => _('Search'),
            onclick => {
                submit  => $search,
                refresh => Jifty->web->current_region->parent,
                args    => { page => 1 }
            }
        );
        hr {};
      }
};

template '__jifty/admin/fragments/list/update' => sub {
    my ( $id, $object_type, $mask_field, $mask_val, $list_path ) = get(qw(id object_type mask_field mask_val list_path));
    my $record_class = Jifty->app_class( "Model", $object_type );
    my $record       = $record_class->new();
    my $update       = new_action(
        class   => "Update" . $object_type,
        moniker => "update-" . Jifty->web->serial,
        record  => $record
    );
    with( class => "jifty_admin update item inline $object_type" ), div {
        with( class => "editlink" ), div {
            hyperlink(
                label   => _("Save"),
                onclick => [
                    { submit => $update },
                    {
                        replace_with => $list_path.'view',
                        args => { object_type => $object_type, id => $id, list_path => $list_path }
                    }
                ]
            );

            hyperlink(
                label   => _("Cancel"),
                onclick => {
                    replace_with => $list_path.'view',
                    args         => { object_type => $object_type, id => $id, list_path => $list_path}
                },
                as_button => 1
            );

        };
        if ($mask_field) {
        $update->hidden($mask_field, $mask_val);
        }

        foreach my $argument ( $update->argument_names ) {
            if ( $argument ne $mask_field ) {
            render_param( $update => $argument );
            }
        }
        hr {};
    };
};

template '__jifty/admin/fragments/list/view' => sub {
    my ( $id, $object_type, $mask_field, $mask_val, $list_path ) = get(qw( id object_type mask_field mask_val list_path ));
    my $record_class = Jifty->app_class( "Model", $object_type );
    my $record = $record_class->new();
    $record->load($id);
    my $update = new_action(
        class   => "Update" . $object_type,
        moniker => "update-" . Jifty->web->serial,
        record  => $record
    );
    my $delete = new_action(
        class   => "Delete" . $object_type,
        moniker => "delete-" . Jifty->web->serial,
        record  => $record
    );

    with( class => "jifty_admin read item inline" ), div {

        Jifty->web->form->submit(
            class   => "editlink",
            label   => _("Delete"),
            onclick => [
               { confirm => _("Confirm delete?")},
                {submit  => $delete},
                {delete  => Jifty->web->current_region->qualified_name }
            ]
        );
        hyperlink(
            label   => _("Edit"),
            class   => "editlink",
            onclick => {
                replace_with => $list_path."update",
                args         => { object_type => $object_type, id => $id, 
list_path => $list_path, mask_field => $mask_field, mask_val => $mask_val}
            },
            as_button => 1
        );

        $delete->hidden( 'id', $id );
        foreach my $argument ( $update->argument_names ) {
            unless ( $argument eq $mask_field ||  $argument =~ /_confirm$/
                && lc $update->arguments->{$argument}{render_as} eq 'password' )
            {
                render_param( $update => $argument, render_mode => 'read' );
            }
        }

        hr {};
    };

};

template '__jifty/admin/index' => page {
    title is 'Jifty Administrative Console' ;

        h1 { _('Database Administration') };

        p {
            _(
'This console lets you manage the records in your Jifty database. Below, you should see a list of all your database tables. Feel free to go through and add, delete or modify records.'
            );
        };

        p {
            _(
'To disable this administrative console, add "AdminMode: 0" under the "framework:" settings in the config file (etc/config.yml).'
            );
        };

        h2 { _('Models') };
        ul {
            foreach my $model ( Jifty->class_loader->models ) {
                next unless $model->isa('Jifty::Record');
                next unless ( $model =~ /^(?:.*)::(.*?)$/ );
                my $type = $1;
                li {
                    hyperlink(
                        url   => '/__jifty/admin/model/' . $type,
                        label => $type
                    );
                };
            }
        };
        h2 { _('Actions') };
        ul {
            foreach my $action ( Jifty->api->actions ) {
                Jifty::Util->require($action);
                next
                  if (  $action->can('autogenerated')
                    and $action->autogenerated );
                li {
                    hyperlink(
                        url   => '/__jifty/admin/action/' . $action,
                        label => $action
                    );
                };
            }
        };
        h2 { _('Done?') };
        Jifty->web->return(
            to    => "/",
            label => _('Back to the application')
        );
};

template '__jifty/admin/model/dhandler' => page {
    # XXX move to dispatcher
    my $object_type = die('$m->dhandler_arg');

    my $collection_class =
      Jifty->app_class( "Model", $object_type . "Collection" );
    my $records = $collection_class->new();
    $records->unlimit;
        h1 { _( 'Manage records: [_1]', $object_type ) };
        form {
            Jifty->web->region(
                name     => "admin-$object_type",
                path     => "/__jifty/admin/fragments/list/list",
                defaults => {
                    object_type   => $object_type,
                    render_submit => 1
                }
            );

        };

        h2 { _('Done?') };
        hyperlink(
            url   => "/__jifty/admin/",
            label => _('Back to the admin console')
        );

};

warn "and here";
1;
