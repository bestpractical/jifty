package Jifty::View::Declare::CRUD;
use strict;
use Jifty::View::Declare -base;

sub object_type {
    my $self = shift;
    return $self->package_variable('object_type')|| get('object_type');
}

sub fragment_for {
    my $self = shift;
    return ($self->package_variable('base_path')|| '/crud')."/". shift;
}

sub get_record {
    my ($self, $id) = @_;

    my $record_class = Jifty->app_class("Model", $self->object_type);
    my $record = $record_class->new();
    $record->load($id);

    return $record;
}

template 'search' => sub {

 b{i{   'search goes here.'}};
};

template 'view' => sub {
    my $self = shift;
    my ( $object_type, $id ) = ( $self->object_type, get('id') );
    my $update = new_action(
        class => 'Update' . $object_type,
        moniker => "update-" . Jifty->web->serial,
        record  => $self->get_record( $id )
    );

    div {{ class is 'crud read item inline' };
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
                || lc $update->arguments->{$_}{render_as} eq
                'password' )
            } $update->argument_names;
        render_action( $update, \@fields,
            { render_mode => 'read' } );
	hr {};
    };

};

template 'update' => sub {
    my $self = shift;
    my ( $object_type, $id ) = ($self->object_type, get('id'));

    my $record_class = Jifty->app_class( "Model", $object_type );
    my $record = $record_class->new();
    $record->load($id);
    my $update = new_action(
        class   => "Update" . $object_type,
        moniker => "update-" . Jifty->web->serial,
        record  => $record
    );

    div {{ class is "crud update item inline " . $object_type }

        div {{ class is 'crud editlink' };
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
                        args => { object_type => $object_type, id => $id }
                    },
                    as_button => 1
            );
        };

        $self->render_action( $update );
        hr {};
    }
};

template 'list' => sub {
    my $self = shift;
    my ( $object_type, $page, $new_slot_path, $item_path, $search_collection )
        = ($self->object_type, get(qw(page new_slot_path item_path search_collection)));

    $item_path ||= $self->fragment_for("view");

    my $collection_class
        = Jifty->app_class( "Model", $object_type . "Collection" );
    my $search = $search_collection || Jifty->web->response->result('search');
    my $collection;
    if ( !$search ) {
        $collection = $collection_class->new();
        $collection->unlimit();
    } else {
	$collection = $search;
#        $collection = $search->content('search');
    }

    $collection->set_page_info(
        current_page => $page,
        per_page     => 25
    );
    my $search_region = Jifty::Web::PageRegion->new(
        name => 'search',
        path => '/__jifty/empty',
    );

    hyperlink(
    onclick => [{
        region       => $search_region->qualified_name,
        replace_with => $self->fragment_for('search'),
        toggle       => 1,
        args         => { object_type => $object_type }
    },
    ],
    label => 'Toggle search'
    );

    outs( $search_region->render );

    if ( $collection->pager->last_page > 1 ) {
        span {{ class is 'page-count' };
            outs(
                _( "Page %1 of %2", $page, $collection->pager->last_page ) );
            }
    }

    if ( $collection->pager->total_entries == 0 ) {
        outs( _("No items found") );
    }

    div {{ class is 'list' };
        while ( my $item = $collection->next ) {
            render_region(
                    name     => 'item-' . $item->id,
                    path     => $item_path,
                    defaults =>
                        { id => $item->id, object_type => $object_type }
            );
        }
    };

    div {{ class is 'paging' };
        if ( $collection->pager->previous_page ) {
            span {{ class is 'prev-page' };
                hyperlink(
                        label   => "Previous Page",
                        onclick => {
                            args =>
                                { page => $collection->pager->previous_page }
                        }
                );
                }
        }
        if ( $collection->pager->next_page ) {
            span {{ class is 'next-page' };
                hyperlink(
                        label   => "Next Page",
                        onclick => {
                            args => { page => $collection->pager->next_page }
                        }
                );
                }
        }
    };

    if ($new_slot_path) {
        render_region(
                name     => 'new_item',
                path     => $new_slot_path,
                defaults => { object_type => $object_type },
        );
    }
};


template 'new_item' => sub {
    my ( $object_type, $id ) = ($self->object_type, get('id'));

    my $record_class = Jifty->app_class("Model", $object_type);
    my $create = Jifty->web->new_action(class => 'Create'.$object_type);

    div {{ class is 'crud create item inline' };
        $self->render_action( $create );

        outs(
            Jifty->web->form->submit(
                label   => 'Create',
                onclick => [
                    { submit       => $create },
                    { refresh_self => 1 },
                    {   element => undef,#$region->parent->get_element('div.list'),
                        append  => $self->fragment_for('view'),
                        args    => {
                            object_type => $object_type,
                            id => { result_of => $create, name => 'id' },
                        },
                    },
                ]
            )
        );
    }
};

# render tabview using yui.

# if a tab ends in _tab, it means it should contain a stub region to
# be replaced by the corresponding fragment onclick to that tab.

sub render_tabs {
    my ($self, $divname, $args, @tabs) = @_;

    outs_raw(qq'<script type="text/javascript">
	var myTabs = new YAHOO.widget.TabView("$divname");
	</script>'  );


    div { { id is $divname, class is 'yui-navset'}
	  ul { { class is 'yui-nav'};
	       my $i = 0;
	       for (@tabs) {
		   my $tab = $_;
		   li { { class is 'selected' unless $i };
			hyperlink(url => '#tab'.++$i, label => $tab,
				  $tab =~ s/_tab$// ? 
				  (onclick =>
				  { region       => Jifty->web->current_region->qualified_name."-$tab-tab",
				    replace_with => $self->fragment_for($tab),
				    args => { map { $_ => get($_)} @$args },
				  }) : ()
				 ) }
	       }
	   };
	  div { {class is 'yui-content' };
		for (@tabs) {
		    div { 
			if (s/_tab$//) {
			    render_region(name => $_.'-tab');
			}
			else {
			    die "$self $_" unless $self->has_template($_);
			    $self->has_template($_)->(); 
			}
		    }
		}
	    }
      };
};

1;

