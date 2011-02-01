package Jifty::Web::Menu;

use strict;
use warnings;


use base qw/Class::Accessor::Fast/;
use URI;
use Scalar::Util qw(weaken);

__PACKAGE__->mk_accessors(qw(
    label sort_order link target escape_label class render_children_inline
    raw_html
));

=head1 NAME

Jifty::Web::Menu - Handle the API for menu navigation

=head1 METHODS

=head2 new PARAMHASH

Creates a new L<Jifty::Web::Menu> object.  Possible keys in the
I<PARAMHASH> are L</label>, L</parent>, L</sort_order>, L</url>, and
L</active>.  See the subroutines with the respective name below for
each option's use.

=cut

sub new {
    my $package = shift;
    my $args = ref($_[0]) eq 'HASH' ? shift @_ : {@_};

    my $parent = delete $args->{'parent'};
    $args->{sort_order} ||= 0;

    # Class::Accessor only wants a hashref;
    my $self = $package->SUPER::new( $args );

    # make sure our reference is weak
    $self->parent($parent) if defined $parent;

    return $self;
}


=head2 label [STRING]

Sets or returns the string that the menu item will be displayed as.

=cut

=head2 parent [MENU]

Gets or sets the parent L<Jifty::Web::Menu> of this item; this defaults
to null. This ensures that the reference is weakened.

=head2 raw_html [STRING]

Sets the content of this menu item to a raw blob of HTML. When 
asked or output, rather than constructing a link, Jifty will return 
this raw content. No escaping is done.

=cut

sub parent {
    my $self = shift;
    if (@_) {
        $self->{parent} = shift;
        weaken $self->{parent};
    }

    return $self->{parent};
}


=head2 sort_order [NUMBER]

Gets or sets the sort order of the item, as it will be displayed under
the parent.  This defaults to adding onto the end.

=head2 link

Gets or set a L<Jifty::Web::Form::Link> object that represents this
menu item. If you're looking to do complex ajaxy things with menus,
this is likely the option you want.

=head2 target [STRING]

Get or set the frame or pseudo-target for this link. something like L<_blank>

=cut

=head2 class [STRING]

Gets or sets the CSS class the link should have in addition to the default
classes.  This is only used if L</link> isn't specified.

=head2 render_children_inline [BOOLEAN]

Gets or sets whether children are rendered inline as a menu "group" instead
of a true submenu.  Only used when rendering with YUI for now.
Defaults to false.

Note that YUI doesn't support rendering nested menu groups, so having direct
parent/children render_children_inline is likely not going to do what you
want or expect.

=head2 url

Gets or sets the URL that the menu's link goes to.  If the link
provided is not absolute (does not start with a "/"), then is is
treated as relative to it's parent's url, and made absolute.

=cut

sub url {
    my $self = shift;
    if (@_) {
        $self->{url} = shift;
        $self->{url} = URI->new_abs($self->{url}, $self->parent->url . "/")->as_string
            if defined $self->{url} and $self->parent and $self->parent->url;
        $self->{url} =~ s!///!/! if $self->{url};
    }
    return $self->{url};
}

=head2 active [BOOLEAN]

Gets or sets if the menu item is marked as active.  Setting this
cascades to all of the parents of the menu item.

=cut

sub active {
    my $self = shift;
    if (@_) {
        $self->{active} = shift;
        $self->parent->active($self->{active}) if defined $self->parent;
    }
    return $self->{active};
}

=head2 child KEY [, PARAMHASH]

If only a I<KEY> is provided, returns the child with that I<KEY>.

Otherwise, creates or overwrites the child with that key, passing the
I<PARAMHASH> to L<Jifty::Web::Menu/new>.  Additionally, the paramhash's
L</label> defaults to the I<KEY>, and the L</sort_order> defaults to the
pre-existing child's sort order (if a C<KEY> is being over-written) or
the end of the list, if it is a new C<KEY>.

If the paramhash contains a key called C<menu>, that will be used instead
of creating a new Jifty::Web::Menu.


=cut

sub child {
    my $self  = shift;
    my $key   = shift;
    my $proto = ref $self || $self;

    if ( my %args = @_ ) {

        # Clear children ordering cache
        delete $self->{children_list};

        my $child;
        if ( $child = $args{menu} ) {
            $child->parent($self);
        } else {
            $child = $proto->new(
                {   parent     => $self,
                    label        => $key,
                    escape_label => 1,
                    %args
                }
            );
        }
        $self->{children}{$key} = $child;

        $child->sort_order( $args{sort_order} || (scalar values %{ $self->{children} })  )
            unless ($child->sort_order());

        # URL is relative to parents, and cached, so set it up now
        $child->url( $child->{url} );

        # Figure out the URL
        my $url
            = (     defined $child->link
                and ref $child->link
                and $child->link->can('url') )
            ? $child->link->url
            : $child->url;

        # Activate it
        if ( defined $url and length $url and Jifty->web->request ) {

            # XXX TODO cleanup for mod_perl
            my $base_path = Jifty->web->request->path;
            chomp($base_path);

            $base_path =~ s/index\.html$//;
            $base_path =~ s/\/+$//;
            $url       =~ s/\/+$//;

            if ( $url eq $base_path ) {
                $self->{children}{$key}->active(1);
            }
        }
    }

    return $self->{children}{$key};
}

=head2 active_child

Returns the first active child node, or C<undef> is there is none.

=cut

sub active_child {
    my $self = shift;
    foreach my $kid ($self->children) {
        return $kid if $kid->active;
    }
    return undef;
}


=head2 delete KEY

Removes the child with the provided I<KEY>.

=cut

sub delete {
    my $self = shift;
    my $key = shift;
    delete $self->{children_list};
    delete $self->{children}{$key};
}

=head2 children

Returns the children of this menu item in sorted order; as an array in
array context, or as an array reference in scalar context.

=cut

sub children {
    my $self = shift;
    my @kids;
    if ($self->{children_list}) {
        @kids = @{$self->{children_list}};
    } else {
        @kids = values %{$self->{children} || {}};
        @kids = sort {$a->{sort_order} <=> $b->{sort_order}} @kids;
        $self->{children_list} = \@kids;
    }
    return wantarray ? @kids : \@kids;
}

=head2 render_as_menu

Render this menu with HTML markup as multiple dropdowns, suitable for
an application's menu

Any arguments are passed to L<render_as_hierarchical_menu_item>.

=cut

sub render_as_menu {
    my $self = shift;
    my @kids = $self->children;
    Jifty->web->out(qq{<ul class="menu">});

    for (@kids) {
        $_->render_as_hierarchical_menu_item(@_);
    }
    Jifty->web->out(qq{</ul>});
    '';
}

=head2 render_as_context_menu

Render this menu with html markup as an inline dropdown menu.

=cut

sub render_as_context_menu {
    my $self = shift;
    Jifty->web->out( qq{<ul class="context_menu">});
    $self->render_as_hierarchical_menu_item();
    Jifty->web->out(qq{</ul>});
    '';
}

=head2 render_as_hierarchical_menu_item

Render an <li> for this item. suitable for use in a regular or contextual
menu. Currently renders one level of submenu, if it exists, using
L</render_submenu>.

Any arguments are passed to L<render_submenu>.

=cut

sub render_as_hierarchical_menu_item {
    my $self = shift;
    my %args = (
        class => '',
        @_
    );
    my @kids = $self->children;
    my $web  = Jifty->web;
    $web->out( qq{<li class="toplevel }
            . ( $self->active ? 'active' : 'closed' ) .' '.($self->class||"").' '. qq{">}
            . qq{<span class="title">} );
    $web->out( $self->as_link );
    $web->out(qq{</span>});
    if (@kids) {
        my $id = $web->serial;
        $web->out(
            qq{<span class="expand"><a href="#" onclick="Jifty.ContextMenu.hideshow('}
                . $id
                . qq{'); return false;">&nbsp;</a></span>} );
        $self->render_submenu( %args, id => $id );
    }
    $web->out(qq{</li>});
    '';

}

=head2 render_submenu

Renders a <ul> for the children (but not descendants) of this menu object,
suitable for use as part of a regular or contextual menu.  Called by
L</render_as_hierarchical_menu_item>. You probably don't need to use this
on it's own.

If passed C<deep_active => 1>, then it renders active descendants recursively
all the way down.

=cut

sub render_submenu {
    my $self = shift;
    my %args = (
        id => '',
        deep_active => 0,
        @_
    );

    my $web = Jifty->web;
    $web->out(qq(<ul id="$args{id}" class="submenu">));
    for ($self->children) {
        $web->out(qq{<li class="submenu }.($_->active ? 'active' : '' ).' '. ($_->class || "").qq{">});

        # We should be able to get this as a string.
        # Either stringify the link object or output the label
        # This is really icky. XXX TODO
        $web->out( $_->as_link );
    
        if ($args{'deep_active'} and $_->active and $_->children) {
            $_->render_submenu( %args, id => $web->serial );
        }

        $web->out("</li>");
    }
    $web->out(qq{</ul>});
}

=head2 render_as_classical_menu

Render this menu with html markup as old classical mason menu. 
Currently renders one level of submenu, if it exists.

=cut

sub  render_as_classical_menu {
    my $self = shift;
    my @kids = $self->children;

    Jifty->web->out( qq{<ul class="menu">});

    for (@kids) {
        $_->_render_as_classical_menu_item();
    }

    Jifty->web->out(qq{</ul>});
    '';
}

sub _render_as_classical_menu_item {
    my $self = shift;
    my %args = (
        class => '',
        @_
    );
    my @kids = $self->children;
    Jifty->web->out( qq{<li} . ($self->active ? qq{ class="active"} : '' ) . qq{>} );
    Jifty->web->out( $self->as_link );
    if (@kids) {
      Jifty->web->out( qq{<ul class="submenu">} );
      for (@kids) {
         Jifty->web->out( qq{<li} . ($_->active ? qq{ class="active"} : '' ) . qq{>} );
         Jifty->web->out( $_->as_link );
         Jifty->web->out("</li>");
      }
      Jifty->web->out(qq{</ul>});
    }
    Jifty->web->out(qq{</li>});
    '';

}

=head2 render_as_yui_menu [PARAMHASH]

Render menu with YUI menu.  It can support arbitrary levels of submenus.

Valid options for the paramhash are as follows:

=over

=item id

The HTML element ID to use for the menu

=item show

A boolean indicating whether to show the menu after rendering the HTML.
Defaults to true.  If you don't set this to true, you should use the
button option (see below) or show the menu with Javascript like:

    YAHOO.widget.MenuManager.getMenu("menu-html-id").show();

=item button

The ID of an HTML element.  The element's onclick Javascript event is bound
to a function which shows the menu.

=item options

A hashref of options passed directly to the Javascript constructor for
the menu.  See L<http://developer.yahoo.com/yui/menu/#configreference> for
a list of the options available.

=item beforeshow

A string of Javascript to run immediately before the menu is shown.  The
variable C<menu> is available and represents the current YUI Menu object.

=back

=cut

sub render_as_yui_menu {
    my $self = shift;
    my %args = (
        id      => Jifty->web->serial,
        show    => 1,
        options => {},
        beforeshow => '',
        @_
    );

    my $showjs = $args{'show'} ? "menu.show();" : "";
    my $json   = Jifty::JSON::encode_json( $args{'options'} );

    # Bind to a button to show the menu
    my $binding = (defined $args{'button'} and length $args{'button'}) ? 1 : 0;

    $self->_render_as_yui_menu_item( class => "yuimenu", id => $args{'id'} );

    Jifty->web->out(<<"    END");
        <script type="text/javascript">
            YAHOO.util.Event.onContentReady("$args{id}", function() {
                // set container?
                var menu = new YAHOO.widget.Menu("$args{id}", $json);
                menu.render();
                menu.subscribe("show", function() {
                    if ( !this.cfg.getProperty("constraintoviewport") )
                        Jifty.Utils.scrollToShow(this.id);
                });
                if ( $binding ) {
                    YAHOO.util.Event.addListener("$args{button}", "click",
                        function() {
                           this.show();
                        },
                        null, menu
                    );
                    menu.subscribe("show", function() { if (!this.parent) jQuery("#$args{button}").addClass("open") });
                    menu.subscribe("hide", function() { if (!this.parent) jQuery("#$args{button}").removeClass("open") });
                }
                $args{beforeshow}
                $showjs
            });
        </script>
    END
    '';
}

=head2 render_as_yui_menubar

Render menubar with YUI menu, suitable for an application's menu.
It can support arbitrary levels of submenu.

=cut

sub render_as_yui_menubar {
    my $self = shift;
    my $id   = shift || Jifty->web->serial;
    $self->_render_as_yui_menu_item( class => "yuimenubar", id => $id );
    Jifty->web->out(qq|<script type="text/javascript">\n|
        . qq|YAHOO.util.Event.onContentReady("|.$id.qq|", function() {\n|
        . qq|var menu = new YAHOO.widget.MenuBar("|.$id.qq|", { autosubmenudisplay:true, hidedelay:750, lazyload:true, showdelay:0 });\n|
        . qq|menu.render();\n|
        . qq|});</script>|
        );
    '';
}

sub _render_as_yui_menu_item {
    my $self = shift;
    my %args = ( class => 'yuimenu', first => 0, id => undef, @_ );
    my @kids = $self->children or return;
    
    # Add the appropriate YUI class to each kid
    for my $kid ( @kids ) {
        # Skip it if it's a group heading
        next if $kid->render_children_inline and $kid->children;

        # Figure out the correct object to be setting the class on
        my $object =   ( defined $kid->link
                     and ref $kid->link
                     and $kid->link->can('class') )
                         ? $kid->link : $kid;

        my $class = defined $object->class ? $object->class . ' ' : '';
        $class .= "$args{class}itemlabel";
        $object->class( $class );
    }

    # We're rendering this inline, so just render a UL (and any submenus as normal)
    if ( $self->render_children_inline ) {
        Jifty->web->out( $args{'first'} ? '<ul class="first-of-type">' : '<ul>' );
        for my $kid ( @kids ) {
            Jifty->web->out( qq(<li class="$args{class}item ) . ($kid->active? 'active' : '') . qq{">});
            Jifty->web->out( $kid->as_link );
            $kid->_render_as_yui_menu_item( class => 'yuimenu' );
            Jifty->web->out( qq{</li>});
        }
        Jifty->web->out('</ul>');
    }
    # Render as normal submenus
    else {
        Jifty->web->out(
            qq{<div}
            . ($args{'id'} ? qq( id="$args{'id'}") : "")
            . qq( class="$args{class}"><div class="bd" @{[($args{id} ? "id=\"$args{id}-bd\"" : "")]}>)
        );

        my $count    = 1;
        my $count_h6 = 1;
        my $openlist = 0;

        for my $kid ( @kids ) {
            # We want to render the children of this child inline, so close
            # any open <ul>s, render it as an <h6>, and then render it's
            # children.
            if ( $kid->render_children_inline and $kid->children ) {
                Jifty->web->out('</ul>') if $openlist;
                
                my @classes = ();
                push @classes, 'active' if $kid->active;
                push @classes, 'first-of-type'
                    if $count_h6 == 1 and $count == 1;

                Jifty->web->out(qq(<h6 class="@{[ join ' ', @classes ]}">));
                Jifty->web->out( $kid->as_link );
                Jifty->web->out('</h6>');
                $kid->_render_as_yui_menu_item(
                    class => 'yuimenu',
                    first => ($count == 1 ? 1 : 0)
                );
                $openlist = 0;
                $count_h6++;
            }
            # It's a normal child
            else {
                if ( not $openlist ) {
                    Jifty->web->out( $count == 1 ? '<ul class="first-of-type">' : '<ul>' );
                    $openlist = 1;
                }
                Jifty->web->out( qq(<li class="$args{class}item ) . ($kid->active? 'active' : '') . qq{">});
                Jifty->web->out( $kid->as_link );
                $kid->_render_as_yui_menu_item( class => 'yuimenu' );
                Jifty->web->out( qq{</li>});
            }
            $count++;
        }
        Jifty->web->out('</ul>') if $openlist;
        Jifty->web->out(qq{</div></div>});
    }
}

=head2 as_link

Return this menu item as a L<Jifty::Web::Form::Link>, either the one
we were initialized with or a new one made from the L</label> and L</url>

If there's no L</url> and no L</link>, renders just the label.

=cut

sub as_link {
    my $self = shift;
    # Stringifying $self->link may return '' and output something, so
    # we need to be careful to not stringify it more than once, and to
    # check it for defined-ness, not truth.
    if  ( my $raw = $self->raw_html) {
        return $raw;
    }
    elsif ( defined (my $str = $self->link) ) {
        return $str;
    } elsif ( $self->url ) {
        return Jifty->web->link( label => _( $self->label ),
                                 url   => $self->url,
                                 escape_label => $self->escape_label,
                                 target => $self->target,
                                 class => $self->class );
    } else {
        if ( $self->class ) {
            return "<span class=\"@{[$self->class]}\">"._( $self->label )."</span>";
        } else {
            return _( $self->label );
        }
    }
}

1;
