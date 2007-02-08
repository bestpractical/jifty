package Jifty::View::Declare::CoreTemplates;

use strict;
use warnings;
use vars qw( $r );

use Jifty::View::Declare -base;

use Scalar::Defer;

template '_elements/nav' => sub {
    my $top = Jifty->web->navigation;
    $top->child( Home => url => "/", sort_order => 1, label => _('Home') );
    if ( Jifty->config->framework('AdminMode') ) {
        $top->child(
            Administration =>
              url          => "/__jifty/admin/",
            label      => _('Administration'),
            sort_order => 998
        );
        $top->child(
            OnlineDocs =>
              url      => "/__jifty/online_docs/",
            label      => _('Online docs'),
            sort_order => 999
        );
    }
    return ();
};

template '_elements/sidebar' => sub {
    with( id => "salutation" ), div {
        if (    Jifty->web->current_user->id
            and Jifty->web->current_user->user_object )
        {
            my $u      = Jifty->web->current_user->user_object;
            my $method = $u->_brief_description;
            _( 'Hiya, %1.', $u->$method() );
        }
        else {
            _("You're not currently signed in.");
        }
    };
    with( id => "navigation" ), div {
        Jifty->web->navigation->render_as_menu;
    };
};

template '_elements/header' => sub {
    my ($title) = get_current_attr(qw(title));
    Jifty->handler->apache->content_type('text/html; charset=utf-8');
    head {
        with(
            'http-equiv' => "content-type",
            content      => "text/html; charset=utf-8"
          ),
          meta {};
        with( name => 'robots', content => 'all' ), meta {};
        title { _($title) };

        Jifty->web->include_css;
        Jifty->web->include_javascript;
      }
};

template '__jifty/subs' => sub {
    my ($forever) = get(qw(forever)) || 1;

    Jifty->handler->apache->content_type("text/html; charset=utf-8");
    Jifty->handler->apache->headers_out->{'Pragma'}        = 'no-cache';
    Jifty->handler->apache->headers_out->{'Cache-control'} = 'no-cache';
    Jifty->handler->apache->send_http_header;

    my $writer = XML::Writer->new;
    $writer->xmlDecl( "UTF-8", "yes" );

    my $begin = <<'END';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
 "http://www.w3.org/TR/2002/REC-xhtml1-20020801/DTD/xhtml1-strict.dtd">
<html><head><title></title></head>
END
    chomp $begin;

    if ($forever) {
        my $whitespace = " " x ( 1024 - length $begin );
        $begin =~ s/<body>$/$whitespace/s;
    }

    Jifty->web->out($begin);
    $writer->startTag("body");

    while (1) {
        my $sent = write_subs_once($writer);
        flush STDOUT;
        last if ( $sent && !$forever );
        sleep 1;
    }
    $writer->endTag();
    return;

};

sub write_subs_once {
    my $writer = shift;
    Jifty::Subs::Render->render(
        Jifty->web->session->id,
        sub {
            my ( $mode, $name, $content ) = @_;
            $writer->startTag( "pushfrag", mode => $mode );
            $writer->startTag( "fragment", id   => $name );
            $writer->dataElement( "content", $content );
            $writer->endTag();
            $writer->endTag();
        }
    );
}

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

    my $action = new_action(
        class   => $action_class,
        moniker => "run-$action_class",
    );

    $action->sticky_on_failure(1);
    wrapper {

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
    my ( $object_type, $page, $new_slot, $item_path ) =
      get(qw( object_type page new_slot item_path ));

    $page ||= 1;
    $new_slot = 1 unless defined $new_slot;
    $item_path ||= "/__jifty/admin/fragments/list/view";

    my $collection_class =
      Jifty->app_class( "Model", $object_type . "Collection" );
    my $search = Jifty->web->response->result('search');
    my $collection;
    if ( !$search ) {
        $collection = $collection_class->new();
        $collection->unlimit();
    }
    else {
        $collection = $search->content('search');
        warn $collection->build_select_query;
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
        onclick => [
            {
                region       => $search_region->qualified_name,
                replace_with => '/__jifty/admin/fragments/list/search',
                toggle       => 1,
                args         => { object_type => $object_type }
            },
        ],
        label => _('Toggle search')
    );

    $search_region->render;

    if ( $collection->pager->last_page > 1 ) {
        with( class => "page-count" ), span {
            _( 'Page %1 of %2', $page, $collection->pager->last_page );
          }
    }

    if ( $collection->pager->total_entries == 0 ) {
        _('No items found');
    }

    with( class => "list" ), div {
        while ( my $item = $collection->next ) {
            Jifty->web->region(
                name     => 'item-' . $item->id,
                path     => $item_path,
                defaults => { id => $item->id, object_type => $object_type }
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
            path     => "/__jifty/admin/fragments/list/new_item",
            defaults => { object_type => $object_type },
        );
    }

};

# When you hit "save" and create a item, you want to put a fragment
# containing the new item in the associated list and refresh the current
# fragment
#
template '__jifty/admin/fragments/list/new_item' => sub {
    my ( $object_type, $region ) = get(qw(object_type region));
    my $record_class = Jifty->app_class( "Model", $object_type );
    my $create = new_action( class => 'Create' . $object_type );
    with( class => "jifty_admin create item inline" ), div {
        foreach my $argument ( $create->argument_names ) {
            render_param( $create => $argument );
        }
    };

    Jifty->web->form->submit(
        label   => _('Create'),
        onclick => [
            { submit       => $create },
            { refresh_self => 1 },
            {
                element => $region->parent->get_element('div.list'),
                append  => '/__jifty/admin/fragments/list/view',
                args    => {
                    object_type => $object_type,
                    id          => { result_of => $create, name => 'id' },
                },
            },
        ]
      )

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
    my ( $id, $object_type ) = get(qw(id object_type));
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
                        replace_with => '/__jifty/admin/fragments/list/view',
                        args => { object_type => $object_type, id => $id }
                    }
                ]
            );

            hyperlink(
                label   => _("Cancel"),
                onclick => {
                    replace_with => '/__jifty/admin/fragments/list/view',
                    args         => { object_type => $object_type, id => $id }
                },
                as_button => 1
            );

        };

        foreach my $argument ( $update->argument_names ) {
            render_param( $update => $argument );
        }
        hr {};
    };
};

template '__jifty/admin/fragments/list/view' => sub {
    my ( $id, $object_type ) = get(qw( id object_type ));
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
            submit  => $delete,
            onclick => {
                confirm => _("Confirm delete?"),
                delete  => Jifty->web->current_region->qualified_name
            },
        );
        hyperlink(
            label   => _("Edit"),
            class   => "editlink",
            onclick => {
                replace_with => "/__jifty/admin/fragments/list/update",
                args         => { object_type => $object_type, id => $id }
            },
            as_button => 1
        );

        $delete->hidden( 'id', $id );
        foreach my $argument ( $update->argument_names ) {
            unless ( $argument =~ /_confirm$/
                && lc $update->arguments->{$argument}{render_as} eq 'password' )
            {
                render_param( $update => $argument, render_mode => 'read' );
            }
        }

        hr {};
    };

};

template '__jifty/admin/index' => sub {
    with( title => 'Jifty Administrative Console' ), wrapper {

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
      }
};

template '__jifty/admin/model/dhandler' => sub {
    # XXX move to dispatcher
    my $object_type = die('$m->dhandler_arg');

    my $collection_class =
      Jifty->app_class( "Model", $object_type . "Collection" );
    my $records = $collection_class->new();
    $records->unlimit;
    wrapper {
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

      }
};

template '__jifty/autocomplete.xml' => sub {

    # Note: the only point to this file is to set the content_type; the actual
    # behavior is accomplished inside the framework.  It will go away once we
    # have infrastructure for serving things of various content-types.
    Jifty->handler->apache->content_type('text/xml; charset=UTF-8');
    my $ref = Jifty->web->response->result('autocomplete')->content;
    my @options = @{ $ref->{'completions'} || [] };
    body {
        ul {
            foreach my $item (@options) {
                if ( !ref($item) ) {
                    li { $item };
                }
                elsif ( exists $item->{label} ) {
                    li {
                        with( class => "informal" ), span { $item->{label} };
                        with( class => "hidden_value" ),
                          span { $item->{value} };
                    };
                }
                else {
                    li { $item->{value} };
                }
            }
        };
    };
};

template '__jifty/css/dhandler' => sub {
    # XXX move to dispatcher
    if ( die('$m->dhandler_arg') !~ /^[0-9a-f]{32}\.css$/ ) {

        # This doesn't look like a real request for squished CSS,
        # so redirect to a more failsafe place
        Jifty->web->redirect( "/static/css/" . die('$m->dhandler_arg') );
    }

    Jifty->web->generate_css;

    use HTTP::Date ();

    if ( Jifty->handler->cgi->http('If-Modified-Since')
        and die('$m->dhandler_arg') eq Jifty->web->cached_css_digest . '.css' )
    {
        Jifty->log->debug("Returning 304 for cached css");
        Jifty->handler->apache->header_out( Status => 304 );
        return;
    }

    Jifty->handler->apache->content_type("text/css");
    Jifty->handler->apache->header_out( 'Expires' => HTTP::Date::time2str( time + 31536000 ) );

    # XXX TODO: If we start caching the squished CSS in a file somewhere, we
    # can have the static handler serve it, which would take care of gzipping
    # for us.
    use Compress::Zlib qw();

    if ( Jifty::View::Static::Handler->client_accepts_gzipped_content ) {
        Jifty->log->debug("Sending gzipped squished CSS");
        Jifty->handler->apache->header_out( "Content-Encoding" => "gzip" );
        binmode STDOUT;
        print Compress::Zlib::memGzip( Jifty->web->cached_css );
    }
    else {
        Jifty->log->debug("Sending squished CSS");
        print Jifty->web->cached_css;
    }
    return;
};

template '__jifty/empty' => sub {
    '';
};

template '__jifty/error/_elements/error_text' => sub {
    my ($error) = get(qw(error));
    h1 { 'Sorry, something went awry' };
    p  {
        _(
"For one reason or another, you got to a web page that caused a bit of an error. And then you got to our 'basic' error handler. Which means we haven't written a pretty, easy to understand error message for you just yet. The message we do have is :"
        );
    };

    blockquote {
        b { $error };
    };

    p {
        _(
"There's a pretty good chance that error message doesn't mean anything to you, but we'd rather you have a little bit of information about what went wrong than nothing. We've logged this error, so we know we need to write something friendly explaining just what happened and how to fix it."
        );
    };

    p {
        hyperlink(
            url   => "/",
            label => _('Head on back home')
        );
        _("for now, and try to forget that we let you down.");
    };
};

=begin TODO

                    sub __jifty::error::_elements::wrapper {
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
                          < html xmlns =
                          "http://www.w3.org/1999/xhtml" xml : lang =
                          "en" > <head> < title > Mason error </title> <
                          link rel = "stylesheet" type = "text/css" href =
                          "/__jifty/error/error.css" media =
                          "all" / > </head> body {
                            with( id => "headers" ), div {
                                <h1 class="title"> Mason error;
                              }
                          }
                          with( id => "content" ), div {
                            <a name="content"> < /a>
% if (Jifty->config->framework('AdminMode') ) {
with ( class => "warning admin_mode"), div {
Alert: Jifty <% Jifty->web->tangent( label => 'administration mode' , url => '/
                              __jifty / admin /')%> is enabled.
}
% }
  <% Jifty->web->render_messages %>

  <% $m->content |n%>

  }
</ body > </html> < %doc >

                              This exists as a fallback wrapper,
                              in
                              case
                              the mason error in question is caused by the Jifty
                              app's wrapper,
                              for instance
                              .

                              </%doc>;
                          }

                          sub __jifty::error::autohandler {
                            <%flags> inherit => undef </%flags> % $m->call_next;
                        }

                        sub __jifty::error::dhandler {
                            Jifty->log->error(
                                "Unhandled web error " . $m->dhandler_arg );
                            <&|/_elements/wrapper, title =>
                              'Something went awry' & >

                              <& _elements/error_text, error =>
                              $m->dhandler_arg & >

                              </&>;
                        }

                        sub __jifty::error::error . css {
                            Jifty->handler->apache->content_type("text/css");
                            h1 {
                              color: red;
                              }

                          }

                                sub __jifty::halo {
                                    for my $id ( 0 .. $#stack ) {
                                        my @kids;
                                        my $looking = $id;
                                        while ( ++$looking <= $#stack
                                            and $stack[$looking]->{depth} >=
                                            $stack[$id]->{depth} + 1 )
                                        {
                                            push @kids,
                                              {
                                                id   => $stack[$looking]{id},
                                                path => $stack[$looking]{path},
                                                render_time =>
                                                  $stack[$looking]{render_time}
                                              }
                                              if $stack[$looking]->{depth} ==
                                              $stack[$id]->{depth} + 1;
                                        }
                                        $stack[$id]{kids} = \@kids;

                                        if ( $stack[$id]{depth} > 1 ) {
                                            $looking = $id;
                                            $looking--
                                              while ( $stack[$looking]{depth} >=
                                                $stack[$id]{depth} );
                                            $stack[$id]{parent} = {
                                                id   => $stack[$looking]{id},
                                                path => $stack[$looking]{path},
                                                render_time =>
                                                  $stack[$looking]{render_time}
                                            };
                                        }
                                    }

                                    my $depth = 0;

                                    div {
                                        outs_raw(
'<a href="#" id="render_info" onclick="Element.toggle('
                                              render_info_tree
                                              '); return false">Page info</a>'
                                        );
                                    };
                                    with(
                                        style => "display: none",
                                        id    => "render_info_tree"
                                      ),
                                      div {
                                        foreach my $item (@stack) {
                                            if ( $item->{depth} > $depth ) {
                                                ul {
                                                  }
                                                  elsif (
                                                    $item->{depth} < $depth )
                                                {
                                                    for ( $item->{depth} +
                                                        1 .. $depth )
                                                    {
                                                    }
                                                }
                                            }
                                        }
                                      }
                                      elsif ( $item->{depth} == $depth ) {
                                    }
                                }

                                li {
                                    outs_raw(
                                        '<a href="#" class="halo_comp_info" 
    onmouseover="halo_over(' < %$item->{id} % > ')"
    onmouseout="halo_out(' < %$item->{id} % > ')"
    onclick="halo_toggle(' < %$item->{id} % > '); return false;">
<% $item->{' name '} %> - <% $item->{' render_time '} %></a>'
                                    );
                                    unless ( $item->{subcomponent} ) {
                                        Jifty->web->tangent(
                                            url =>
                                              "/__jifty/edit/mason_component/"
                                              . $item->{'path'},
                                            label => _('Edit')
                                        );
                                    }
                                    $depth = $item->{'depth'};
                                  }

                                  for ( 1 .. $depth ) {
                                }
                              }
                        }
                    }

                    %foreach my $item (@stack){
                        <& .frame, frame => $item & > %} my (@stack) =
                          get(qw(stack));

                          <%def .frame> with(
                            class => "halo_actions" id =
                              "halo-<% $id %), div {-menu" style =
"display: none; top: 5px; left: 500px; min-width: 200px; width: 300px; z-index: 5;"
                              > <h1 id="halo-<% $id %> -title ">
  <span style=" float: right;
                              "><a href=" #" onclick="halo_toggle('<% $id %>'); return false">[ X ]</a>}
                              < %$frame->{name} % >
                          } < div style =
                          "position: absolute; bottom: 3px; right: 3px" > with(
                            class => "resize" title = "Resize" id =
                              "halo-<% $id %), span {-resize" >
                          };
                      }

                      with( class => "body" ),
                    div {
                        with( class => "path" ),
                          div { <% $frame-> {path} %> } with( class => "time" ),
                          div {
                            Rendered in < %$frame->{'render_time'} % > s}
}
% if ($frame->{parent}
                          ) {
                            with( class => "section" ),
                            div { Parent } with( class => "body" ),
                            div {
                                ul {
                                    li {
<a href="#" class="halo_comp_info" onmouseover="halo_over('<% $frame->
                                          {parent}{ id }
                                        %> ')"
                                       onmouseout="halo_out(' <
                                          %$frame->{parent}{id} % > ')"
                                       onclick="halo_toggle(' <
                                          %$frame->{parent}{id} % >
                                          '); return false;">
<% $frame->{parent}{' path '} %> - <% $frame->{parent}{' render_time '} %></a>}
}}
% }
% if (@{$frame->{kids}}) {
with ( class => "section"), div {Children}
with ( class => "body"), div {ul { 
% for my $item (@{$frame->{kids}}) {
li {<a href="#" class="halo_comp_info" onmouseover="halo_over(' <
                                          %$item->{id} % > ')"
                                       onmouseout="halo_out(' < %$item->{id} % >
                                          ')"
                                       onclick="halo_toggle(' < %$item->{id} % >
                                          '); return false;">
<% $item->{' path '} %> - <% $item->{' render_time '} %></a>}
% }
}
}
% }
% if (@args) {
with ( class => "section"), div {Variables}
with ( class => "body"), div {<ul class="fixed">
% for my $e (@args) {
li {<b><% $e->[0] %></b>:
% if ($e->[1]) {
% my $expanded = Jifty->web->serial;
<a href="#" onclick="Element.toggle(' < %$expanded % >
                                          '); return false"><% $e->[1] %></a>
with ( id => "<% $expanded %), div {" style="display: none; position: absolute; left: 200px; border: 1px solid black; background: #ccc; padding: 1em; padding-top: 0; width: 300px; height: 500px; overflow: auto"><pre><% Jifty::YAML::Dump($e->[2]) %></pre>}
% } elsif (defined $e->[2]) {
<% $e->[2] %>
% } else {
<i>undef</i>
% }
}
% }
}}
% }
% if (@stmts) {
with ( class => "section"), div {<%_(' SQL Statements ')%>}
with ( class => "body" style="height: 300px; overflow: auto"), div {ul { 
% for (@stmts) {
li {
with ( class => "fixed"), span {<% $_->[1] %>}<br />
% if (@{$_->[2]}) {
<b>Bindings:</b> <tt><% join(',
', map {defined $_ ? ($_ =~ /[^[:space:][:graph:]]/ ? "*BLOB*" : $_ ) : "undef"} @{$_->[2]}) %></tt><br />
% }
<i><% _(' % 1 seconds ', $_->[3]) %></i>
}
 }
}}
 }
with ( class => "section"), div {
 unless ($frame->{subcomponent}) {
Jifty->web->tangent( url =>"/__jifty/edit/mason_component/".$frame->{' path
                                          '}, label => _('Edit'));
 } else {
outs_raw(' &nbsp;
                                        ');
% }
}
}
my ( $frame) = get(qw(frame));
my $id = $frame->{id};

my @args;
while (my ($key, $value) = splice(@{$frame->{args}},0,2)) {
    push @args, [$key, ref($value), $value];
}
@args = sort {$a->[0] cmp $b->[0]} @args;

my $prev = '';
my @stmts = @{$frame->{' sql_statements '}};
</%def>
}

sub __jifty::js::dhandler {
    if ( $m->dhandler_arg !~ /^[0-9a-f]{32}\.js$/ ) {

        # This doesn' t look like a real request for squished JS,

                                          # so redirect to a more failsafe place
                                          Jifty->web->redirect(
                                            "/static/js/" . $m->dhandler_arg );
                                      }

                                      Jifty->web->generate_javascript;

                                    use HTTP::Date ();

                                    if (
                                        Jifty->handler->cgi->http(
                                            'If-Modified-Since')
                                        and $m->dhandler_arg eq
                                        Jifty->web->cached_javascript_digest
                                        . '.js'
                                      )
                                    {
                                        Jifty->log->debug(
"Returning 304 for cached javascript"
                                        );
                                        Jifty->handler->apache->header_out( Status => 304 );
                                        return;
                                    }

                                    Jifty->handler->apache->content_type(
                                        "application/x-javascript");
                                    Jifty->handler->apache->header_out(
                                        'Expires' => HTTP::Date::time2str(
                                            time + 31536000
                                        )
                                    );

       # XXX TODO: If we start caching the squished JS in a file somewhere, we
       # can have the static handler serve it, which would take care of gzipping
       # for us.
                                    use Compress::Zlib qw();

                                    if ( Jifty::View::Static::Handler
                                        ->client_accepts_gzipped_content )
                                    {
                                        Jifty->log->debug(
                                            "Sending gzipped squished JS");
                                        Jifty->handler->apache->header_out(
                                            "Content-Encoding" => "gzip" );
                                        binmode STDOUT;
                                        print Compress::Zlib::memGzip(
                                            Jifty->web->cached_javascript );
                                    }
                                    else {
                                        Jifty->log->debug(
                                            "Sending squished JS");
                                        print Jifty->web->cached_javascript;
                                    }
                                    return;
                                  }

                                  sub __jifty::online_docs::autohandler {

# If "AdminMode" is turned off in Jifty's config file, don't let people at the admin UI.
                                    unless (
                                        Jifty->config->framework('AdminMode') )
                                    {
                                        $m->redirect(
                                            '/__jifty/error/permission_denied');
                                        $m->abort();
                                    }

                                    $m->call_next();
                                }

                                sub __jifty::online_docs::content . html {
                                    <?xml version="1.0" encoding="UTF-8"?> <
                                      !DOCTYPE html PUBLIC
                                      "-//W3C//DTD XHTML 1.1//EN"
"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
                                      > <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" >
                                      < head > <title> <
                                      %_ ( $n || 'Jifty' ) % >
                                      -<%_('Jifty Pod Online')%> < /title>
<style type="text/css"><!--
a { text-decoration: none }
a:hover { text-decoration: underline }
a:focus { background: #99ff99; border: 1px black dotted }
--></style>
</head>
body {
<%PERL>
my $jifty_dirname = Jifty::Util->jifty_root." / ";
my $app_dirname = Jifty::Util->app_root." / lib /";
$n =~ s/ :: /\//g;

                                    my @options = (
                                        $app_dirname . $n . ".pod",
                                        $app_dirname . $n . ".pm",
                                        $jifty_dirname . $n . ".pod",
                                        $jifty_dirname . $n . ".pm"
                                    );

                                    my $total_body;
                                    foreach my $file (@options) {
                                        next unless -r "$file";
                                        local $/;
                                        my $fh;
                                        open $fh, "$file" or next;
                                        $total_body = <$fh>;
                                        close $fh;
                                    }
                                    my $body;
                                    my $schema;
                                    my $converter = Pod::Simple::HTML->new();
                                    if ( $n !~ /^Jifty\// ) {
                                        if ( $total_body =~
/package (.*?)::Schema;(.*)package/ismx
                                          )
                                        {
                                            $schema = $2;
                                        }
                                    }

                                    $converter->output_string( \$body );
                                    $converter->parse_string_document(
                                        $total_body);
                                    $body =~ s{.*?<body [^>]+>}{}s;
                                    $body =~ s{</body>\s*</html>\s*$}{};
                                    $n    =~ s{/}{::}g;
                                    $m->print("h1 {$n}");
                                    $m->print( "h2 {"
                                          . _('Schema')
                                          . "}<pre>$schema</pre>" )
                                      if ($schema);
                                    $body =~
s{<a href="http://search\.cpan\.org/perldoc\?(Jifty%3A%3A[^"]+)"([^>]*)>}{<a href="content.html?n=$1"$2>}g;
                                    $body =~ s!}\n\tul { !ul { !;
                                    $body =~ s!}!}}!;
                                    $body =~ s!p { }!!;
                                    $body =~ s!<a name=!<a id=!g;
                                    $body =~ s!__index__!index!g;
                                    $m->print($body);
                                    </%PERL> < /body></ html >
                                      <%ARGS> $Target => '&method=content' $n =>
                                      'Jifty' < /%ARGS>
require File::Basename;
require File::Find;
require File::Temp;
require File::Spec;
require Pod::Simple::HTML;
}

sub __jifty::online_docs::index.html { 
<!DOCTYPE HTML PUBLIC "-/ / W3C // DTD HTML 4.01 Frameset // EN "
" http: // www . w3 . org / TR / html4 /">
<html lang="en">
<head>
<title><%_( $n || 'Jifty') %> - <%_('Online Documentation')%></ title >
                                      <style type="text/css"> <
                                      !--a     { text-decoration: none }
                                      a: hover { text-decoration: underline }
                                      a: focus {
                                        background: #99ff99; border: 1px black dotted }
                                        --> </style> < /head>
<FRAMESET COLS="*, 250">
    <FRAME src="./content . html " name=" podcontent ">
    <FRAME src=" . /toc.html" name="podtoc">
    <NOFRAMES>
        <a style="display: none" href="#toc"><%_('Table of Contents')%></ a >
                                          <& content.html, Target => '' & > h1 {
                                            <a id="toc"> <
                                              %_ ('Table of Contents') % > </a>;
                                          }
                                          <& toc.html, Target => '' & >
                                          </NOFRAMES> < /FRAMESET>
my (
$n => undef
) = get(qw());
}

sub __jifty::online_docs::toc.html { 
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-/ / W3C // DTD XHTML 1.1 // EN "
" http: // www . w3 . org / TR / xhtml11 / DTD / xhtml11 . dtd ">
<html xmlns=" http: // www . w3 . org / 1999 / xhtml " xml:lang=" en " >
<head>
<title><% _($n || 'Jifty') %> - <%_('Jifty Developer Documentation Online')%></title>
<style type=" text / css "><!--
a { text-decoration: none }
a:hover { text-decoration: underline }
a:focus { background: #99ff99; border: 1px black dotted }
--></style>
</head>
<body style=" background:    #dddddd">
                                          <%PERL> my @found;
                                        File::Find::find(
                                            {
                                                untaint => 1,
                                                wanted  => sub {
                                                    return
                                                      unless
                                                      /(\w+)\.(?:pm|pod)$/;
                                                    my $name =
                                                      $File::Find::name;
                                                    $name =~ s/.*lib\b.//;
                                                    $name =~ s!\.(?:pm|pod)!!i;
                                                    $name =~ s!\W!::!g;
                                                    push @found, $name;
                                                },
                                                follow => ( $^O ne 'MSWin32' )
                                            },
                                            Jifty::Util->app_root . "/lib",
                                        );

                                        File::Find::find(
                                            {
                                                untaint => 1,
                                                wanted  => sub {
                                                    return
                                                      unless $File::Find::name
                                                      =~ /^(?:.*?)(Jifty.*?\.(?:pm|pod))$/;
                                                    my $name = $1;
                                                    $name =~ s/.*lib\b.//;
                                                    $name =~ s!\.(?:pm|pod)!!i;
                                                    $name =~ s!\/!::!g;
                                                    push @found, $name;
                                                },
                                                follow => ( $^O ne 'MSWin32' )
                                            },
                                            Jifty::Util->jifty_root,
                                        );

                                        my $indent = 0;
                                        my $prev   = '';
                                        foreach my $file ( sort @found ) {
                                            my ( $parent, $name ) = ( $1, $2 )
                                              if $file =~ /(?:(.*)::)?(\w+)$/;
                                            $parent = '' unless defined $parent;
                                            if ( $file =~ /^$prev\::(.*)/ ) {
                                                my $foo = $1;
                                                while ( $foo =~ s/(\w+)::// ) {
                                                    $indent++;
                                                    $m->print(
                                                        (
                                                            '&nbsp;&nbsp;&nbsp;'
                                                              x $indent
                                                        )
                                                    );
                                                    $m->print("$1<br />");
                                                }
                                                $indent++;
                                            }
                                            elsif ( $prev !~ /^$parent\::/ ) {
                                                $indent = 0
                                                  unless length $parent;
                                                while ( $parent =~ s/(\w+)// ) {
                                                    next if $prev =~ s/\b$1:://;
                                                    while ( $prev =~ s/::// ) {
                                                        $indent--;
                                                    }
                                                    $m->print(
                                                        (
                                                            '&nbsp;&nbsp;&nbsp;'
                                                              x $indent
                                                        )
                                                    );
                                                    $m->print("$1<br />");
                                                    $indent++;
                                                }
                                            }
                                            elsif (
                                                $prev =~ /^$parent\::(.*::)/ )
                                            {
                                                my $foo = $1;
                                                while ( $foo =~ s/::// ) {
                                                    $indent--;
                                                }
                                            }
                                            $m->print(
                                                (
                                                    '&nbsp;&nbsp;&nbsp;' x
                                                      $indent
                                                )
                                                . '<a target="podcontent" href="content.html?n='
                                                  . $file . '">'
                                                  . $name
                                                  . '</a><br />' . "\n"
                                            );
                                            $prev = $file;
                                        }

                                        </%PERL> < /body></ html >
                                          <%INIT> require File::Basename;
                                        require File::Find;
                                        require File::Temp;
                                        require File::Spec;
                                        require Pod::Simple::HTML;
                                        </%INIT> < %ARGS >
                                          $n => '' $method => '' $Target =>
                                          '&method=content' < /%ARGS>
}
                  }

                  sub autohandler {    # XXX TODO MOVE INTO DISPATCHER
                    Jifty->handler->apache->content_type('text/html; charset=utf-8');

                    if ( $m->base_comp->path =~ m|/_elements/| ) {

                        # Requesting an internal component by hand -- naughty
                        $m->redirect("/errors/requested_private_component");
                    }
                    $m->comp('/_elements/nav');
                }

                sub dhandler {
                    Jifty->log->error(
                        "404: user tried to get to " . $m->dhandler_arg );
                    Jifty->handler->apache->header_out( Status => '404' );
                    with( title => _("Something's not quite right") ),
                      wrapper => {

                        with( id => "overview" ),
                        div {
                            p {
                                join(
                                    " ",
                                    _(
"You got to a page that we don't think exists."
                                    ),
                                    _(
"Anyway, the software has logged this error."
                                    ),
                                    _("Sorry about this . ")
                                );
                              }

                              p {
                                hyperlink(
                                    url   => " / ",
                                    label => _('Go back home...')
                                );
                              }

                          }
                      };
                }

=end TODO

=cut

template '__jifty/validator.xml' => sub {
    Jifty->handler->apache->content_type('text/xml; charset=UTF-8');
    my $output = "";
    use XML::Writer;
    my $writer = XML::Writer->new( OUTPUT => \$output );
    $writer->xmlDecl( "UTF-8", "yes" );
    $writer->startTag("validation");
    for my $ra ( Jifty->web->request->actions ) {
        my $action = Jifty->web->new_action_from_request($ra);
        $writer->startTag( "validationaction", id => $action->register_name );
        for my $arg ( $action->argument_names ) {
            if ( not $action->arguments->{$arg}->{ajax_validates} ) {
                $writer->emptyTag( "ignored",
                    id => $action->error_div_id($arg) );
                $writer->emptyTag( "ignored",
                    id => $action->warning_div_id($arg) );
            }
            elsif ( not defined $action->argument_value($arg)
                    or length $action->argument_value($arg) == 0 )
            {
                $writer->emptyTag( "blank", id => $action->error_div_id($arg) );
                $writer->emptyTag( "blank",
                    id => $action->warning_div_id($arg) );
            }
            elsif ( $action->result->field_error($arg) ) {
                $writer->dataElement(
                    "error",
                    $action->result->field_error($arg),
                    id => $action->error_div_id($arg)
                );
                $writer->emptyTag( "ok", id => $action->warning_div_id($arg) );
            }
            elsif ( $action->result->field_warning($arg) ) {
                $writer->dataElement(
                    "warning",
                    $action->result->field_warning($arg),
                    id => $action->warning_div_id($arg)
                );
                $writer->emptyTag( "ok", id => $action->error_div_id($arg) );
            }
            else {
                $writer->emptyTag( "ok", id => $action->error_div_id($arg) );
                $writer->emptyTag( "ok", id => $action->warning_div_id($arg) );
            }
        }
        $writer->endTag();
        $writer->startTag( "canonicalizeaction", id => $action->register_name );
        for my $arg ( $action->argument_names ) {
            no warnings 'uninitialized';
            if ( $ra->arguments->{$arg} eq $action->argument_value($arg) ) {

                # if the value doesn' t change, it can be ignored .

# canonicalizers can change other parts of the action, so we want to send all changes
                $writer->emptyTag( "ignored",
                    name => $action->form_field_name($arg) );
            }
            elsif ( not defined $action->argument_value($arg)
                or length $action->argument_value($arg) == 0 )
            {
                $writer->emptyTag( "blank",
                    name => $action->form_field_name($arg) );
            }
            else {
                if ( $action->result->field_canonicalization_note($arg) ) {
                    $writer->dataElement(
                        "canonicalization_note",
                        $action->result->field_canonicalization_note($arg),
                        id => $action->canonicalization_note_div_id($arg)
                    );
                }
                $writer->dataElement(
                    "update",
                    $action->argument_value($arg),
                    name => $action->form_field_name($arg)
                );
            }
        }
        $writer->endTag();
    }
    $writer->endTag();
    Jifty->web->out($output);
};

template '__jifty/webservices/xml' => sub {
    my $output = "";
    my $writer = XML::Writer->new(
        OUTPUT => \$output,
        UNSAFE => 1
    );
    $writer->xmlDecl( "UTF-8", "yes" );
    $writer->startTag("response");
    for my $f ( Jifty->web->request->fragments ) {

        # Set up the region stack
        local Jifty->web->{'region_stack'} = [];
        my @regions;
        do {
            push @regions, $f;
        } while ( $f = $f->parent );

        for $f ( reverse @regions ) {
            my $new =
              Jifty->web->get_region( join '-',
                grep { $_ } Jifty->web->qualified_region, $f->name );

            # Arguments can be complex mapped hash values.  Get their
            # real values by mapping.
            my %defaults = %{ $f->arguments || {} };
            for ( keys %defaults ) {
                my ( $key, $value ) = Jifty::Request::Mapper->map(
                    destination => $_,
                    source      => $defaults{$_}
                );
                delete $defaults{$_};
                $defaults{$key} = $value;
            }

            $new ||= Jifty::Web::PageRegion->new(
                name           => $f->name,
                path           => $f->path,
                region_wrapper => $f->wrapper,
                parent         => Jifty->web->current_region,
                defaults       => \%defaults,
            );
            $new->enter;
        }

        # Stuff the rendered region into the XML
        $writer->startTag( "fragment",
            id => Jifty->web->current_region->qualified_name );
        my %args = %{ Jifty->web->current_region->arguments };
        $writer->dataElement( "argument", $args{$_}, name => $_ )
          for sort keys %args;
        $writer->cdataElement( "content",
            Jifty->web->current_region->as_string );
        $writer->endTag();

        Jifty->web->current_region->exit while Jifty->web->current_region;
    }

    my %results = Jifty->web->response->results;
    for ( keys %results ) {
        $writer->startTag(
            "result",
            moniker => $_,
            class   => $results{$_}->action_class
        );
        $writer->dataElement( "success", $results{$_}->success );

        $writer->dataElement( "message", $results{$_}->message )
          if $results{$_}->message;
        $writer->dataElement( "error", $results{$_}->error )
          if $results{$_}->error;

        my %warnings = $results{$_}->field_warnings;
        my %errors   = $results{$_}->field_errors;
        my %fields;
        $fields{$_}++ for keys(%warnings), keys(%errors);
        for ( sort keys %fields ) {
            next unless $warnings{$_} or $errors{$_};
            $writer->startTag( "field", name => $_ );
            $writer->dataElement( "warning", $warnings{$_} )
              if $warnings{$_};
            $writer->dataElement( "error", $errors{$_} )
              if $errors{$_};
            $writer->endTag();
        }

        # XXX TODO: Hack because we don't have a good way to serialize
        # Jifty::DBI::Record's yet, which are technically circular data
        # structures at some level (current_user of a
        # current_user->user_object is itself)
        use Scalar::Util qw(blessed);
        my $content = $results{$_}->content;

        sub stripkids {
            my $top = shift;
            if ( not ref $top ) { return $top }
            elsif (
                blessed($top)
                and (  $top->isa("Jifty::DBI::Record")
                    or $top->isa("Jifty::DBI::Collection") )
              )
            {
                return undef;
            }
            elsif ( ref $top eq 'HASH' ) {
                foreach my $item ( keys %$top ) {
                    $top->{$item} = stripkids( $top->{$item} );
                }
            }
            elsif ( ref $top eq 'ARRAY' ) {
                for ( 0 .. $#{$top} ) {
                    $top->[$_] = stripkids( $top->[$_] );
                }
            }
            return $top;
        }

        $content = stripkids($content);
        use XML::Simple;
        $writer->raw(
            XML::Simple::XMLout(
                $content,
                NoAttr   => 1,
                RootName => "content",
                NoIndent => 1
            )
        ) if keys %{$content};

        $writer->endTag();
    }

    $writer->endTag();
    Jifty->handler->apache->content_type('text/xml; charset=utf-8');
    outs_raw($output);
};

template '__jifty/webservices/yaml' => sub {
    Jifty->handler->apache->content_type("text/x-yaml");
    outs( Jifty::YAML::Dump( { Jifty->web->response->results } ) );
};

template '_elements/keybindings' => sub {
    div { id is "keybindings" };
};

template 'index.html' => page {
    { title is _('Welcome to your new Jifty application') }
    img {
        src is "/static/images/pony.jpg", alt is _(
            'You said you wanted a pony. (Source %1)',
            'http://hdl.loc.gov/loc.pnp/cph.3c13461'
        );
    };
};

template '__jifty/error/mason_internal_error' => page {
    { title is _('Something went awry') }
    my $cont = Jifty->web->request->continuation;
    #my $wrapper = "/__jifty/error/_elements/wrapper" if $cont and $cont->request->path eq "/__jifty/error/mason_internal_error";

    # If we're not in devel, bail
    if ( not Jifty->config->framework("DevelMode") or not $cont ) {
            show("_elements/error_text");
    #    return;
    }

    my $e   = $cont->response->error;
    if (ref($e)) {
    my $msg = $e->message;
    $msg =~ s/, <\S+> (line|chunk) \d+\././;

    my $info  = $e->analyze_error;
    my $file  = $info->{file};
    my @lines = @{ $info->{lines} };
    my @stack = @{ $info->{frames} };

        outs('Error in ');
        _error_line( $file, "@lines" );
        pre {$msg};

        Jifty->web->return( label => _("Try again") );

    h2 { 'Call stack' };
    ul {
        for my $frame (@stack) {
            next if $frame->filename =~ m{/HTML/Mason/};
            li {
                _error_line( $frame->filename, $frame->line );
                }
        }
    }; 
    } else {
    pre {$e};
    }
};

sub _error_line {

    my ( $file, $line ) = (@_);
    if ( -w $file ) {
        my $path = $file;
        for ( map { $_->[1] } @{ Jifty->handler->mason->interp->comp_root } )
        {
            last if $path =~ s/ ^ \Q $_\E //;
        }
        if ( $path ne $file ) {
            outs('template ');
            tangent(
                url        => "/__jifty/edit/mason_component$path",
                label      => "$path line " . $line,
                parameters => { line => $line }
            );
        } else {
            tangent(
                url        => "/__jifty/edit/library$path",
                label      => "$path line " . $line,
                parameters => { line => $line }
            );
        }
    } else {
        outs( '%1 line %2', $file, $line );
    }

}

1;
