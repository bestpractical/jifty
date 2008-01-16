package Jifty::Web::Menu;

use base qw/Class::Accessor::Fast/;
use URI;
use Scalar::Util qw(weaken);

__PACKAGE__->mk_accessors(qw(label _parent sort_order link target escape_label class group));

=head1 NAME

Jifty::Web::Menu - Handle the API for menu navigation

=head1 METHODS

=head2 new PARAMHASH

Creates a new L<Jifty::Web::Menu> object.  Possible keys in the
I<PARAMHASH> are C<label>, C<parent>, C<sort_order>, C<url>, and
C<active>.  See the subroutines with the respective name below for
each option's use.

=cut

sub new {
    my $package = shift;
    my $args = ref($_[0]) eq 'HASH' ? shift @_ : {@_};

    my $parent = delete $args->{'parent'};

    # Class::Accessor only wants a hashref;
    my $self = $package->SUPER::new( $args);

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

=cut


sub parent {
    my $self = shift;
    if (@_) {
        $self->_parent(@_);
        weaken $self->{_parent};
    }

    return $self->_parent;
}


=head2 sort_order [NUMBER]

Gets or sets the sort order of the item, as it will be displayed under
the parent.  This defaults to adding onto the end.

=head2 link

Gets or set a Jifty::Web::Link object that represents this menu item. If
you're looking to do complex ajaxy things with menus, this is likely
the option you want.

=head2 target [STRING]

Get or set the frame or pseudo-target for this link. something like L<_blank>

=cut

=head2 class [STRING]

Gets or sets the CSS class the link should have in addition to the default
classes.  This is only used if C<link> isn't specified.

=head2 group [STRING]

Gets or sets the menu group this menu item is in.  Only used when rendering
as a YUI menubar for now.  Groups are sorted by this value as well.

=head2 url

Gets or sets the URL that the menu's link goes to.  If the link
provided is not absolute (does not start with a "/"), then is is
treated as relative to it's parent's url, and made absolute.

=cut

sub url {
    my $self = shift;
    $self->{url} = shift if @_;

    $self->{url} = URI->new_abs($self->{url}, $self->parent->url . "/")->as_string
      if $self->parent and $self->parent->url;

    $self->{url} =~ s!///!/! if $self->{url};

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
C<label> defaults to the I<KEY>, and the C<sort_order> defaults to the
pre-existing child's sort order (if a C<KEY> is being over-written) or
the end of the list, if it is a new C<KEY>.

=cut

sub child {
    my $self = shift;
    my $key = shift;
    my $proto = ref $self || $self;

    if (@_) {
        $self->{children}{$key} = $proto->new({parent => $self,
                                               sort_order => ($self->{children}{$key}{sort_order}
                                                          || scalar values %{$self->{children}}),
                                               label => $key,
                                               escape_label => 1,
                                               @_
                                             });
        Scalar::Util::weaken($self->{children}{$key}{parent});
        
        # Figure out the URL
        my $child = $self->{children}{$key};
        my $url   =   ( defined $child->link
                    and ref $child->link
                    and $child->link->can('url') )
                        ? $child->link->url : $child->url;

        # Activate it
        if ( defined $url and length $url and Jifty->web->request ) {
            # XXX TODO cleanup for mod_perl
            my $base_path = Jifty->web->request->path;
            chomp($base_path);
            
            $base_path =~ s/index\.html$//;
            $base_path =~ s/\/+$//;
            $url =~ s/\/+$//;
            
            if ($url eq $base_path) {
                $self->{children}{$key}->active(1); 
            }
        }
    }

    return $self->{children}{$key}
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
    delete $self->{children}{$key};
}

=head2 children

Returns the children of this menu item in sorted order; as an array in
array context, or as an array reference in scalar context.

=cut

sub children {
    my $self = shift;
    my @kids = values %{$self->{children} || {}};
    @kids = sort {$a->sort_order <=> $b->sort_order} @kids;
    return wantarray ? @kids : \@kids;
}

=head2 grouped_children

Returns the children of this menu item in grouped sorted order; as an array
of array refs in array context, or as an array ref of array refs in scalar.

=cut

sub grouped_children {
    my $self = shift;
    
    my %group;
    for my $kid ( $self->children ) {
        push @{ $group{$kid->group} }, $kid;
    }

    my @grouped = map  { $group{$_} }
                  sort { $a cmp $b }
                  keys %group;

    return wantarray ? @grouped : \@grouped;
}

=head2 render_as_menu

Render this menu with HTML markup as multiple dropdowns, suitable for
an application's menu

=cut

sub render_as_menu {
    my $self = shift;
    my @kids = $self->children;
    Jifty->web->out(qq{<ul class="menu">});

    for (@kids) {
        $_->render_as_hierarchical_menu_item();
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
menu. Currently renders one level of submenu, if it exists.

=cut

sub render_as_hierarchical_menu_item {
    my $self = shift;
    my %args = (
        class => '',
        @_
    );
    my @kids = $self->children;
    my $id   = Jifty->web->serial;
    Jifty->web->out( qq{<li class="toplevel }
            . ( $self->active ? 'active' : 'closed' ) .' '.($self->class||"").' '. qq{">}
            . qq{<span class="title">} );
    Jifty->web->out( $self->as_link );
    Jifty->web->out(qq{</span>});
    if (@kids) {
        Jifty->web->out(
            qq{<span class="expand"><a href="#" onclick="Jifty.ContextMenu.hideshow('}
                . $id
                . qq{'); return false;">&nbsp;</a></span>}
                . qq{<ul id="}
                . $id
                . qq{">} );
        for (@kids) {
            Jifty->web->out(qq{<li class="submenu }.($_->active ? 'active' : '' ).' '. ($_->class || "").qq{">});

            # We should be able to get this as a string.
            # Either stringify the link object or output the label
            # This is really icky. XXX TODO
            Jifty->web->out( $_->as_link );
            Jifty->web->out("</li>");
        }
        Jifty->web->out(qq{</ul>});
    }
    Jifty->web->out(qq{</li>});
    '';

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

=head2 render_as_yui_menubar [PARAMHASH]

Render menubar with YUI menu, suitable for an application's menu.
It can support arbitary levels of submenu.

=cut

sub render_as_yui_menubar {
    my $self = shift;
    my $id   = Jifty->web->serial;
    $self->_render_as_yui_menu_item("yuimenubar", $id);
    Jifty->web->out(qq|<script type="text/javascript">\n|
        . qq|YAHOO.util.Event.onContentReady("|.$id.qq|", function() {\n|
        . qq|var menu = new YAHOO.widget.MenuBar("|.$id.qq|", { autosubmenudisplay:true, hidedelay:750, lazyload:true, showdelay:0 });\n|
        . qq|menu.render();\n|
        . qq|});</script>|
        );
    '';
}

sub _render_as_yui_menu_item {
    my ($self, $class, $id) = @_;
    my @grouped = $self->grouped_children or return;
    
    Jifty->web->out(
        qq{<div}
        . ($id ? qq{ id="$id"} : "")
        . qq{ class="$class"><div class="bd">}
    );
    my $count = 1;
    for my $group ( @grouped ) {
        Jifty->web->out( $count == 1 ? '<ul class="first-of-type">' : '<ul>' );
        for ( @$group ) {
            Jifty->web->out( qq{<li class="${class}item }
            . ($_->active? 'active' : '') . qq{">});
            Jifty->web->out( $_->as_link );
            $_->_render_as_yui_menu_item("yuimenu");
            Jifty->web->out( qq{</li>});
        }
        Jifty->web->out('</ul>');
        $count++;
    }
    Jifty->web->out(qq{</div></div>});
}

=head2 as_link

Return this menu item as a C<Jifty::Web::Link>, either the one we were
initialized with or a new one made from the C</label> and C</url>

If there's no C</url> and no C</link>, renders just the label.

=cut

sub as_link {
    my $self = shift;
    # Stringifying $self->link may return '' and output something, so
    # we need to be careful to not stringify it more than once, and to
    # check it for defined-ness, not truth.
    if ( defined (my $str = $self->link) ) {
        return $str;
    } elsif ( $self->url ) {
        return Jifty->web->link( label => _( $self->label ),
                                 url   => $self->url,
                                 escape_label => $self->escape_label,
                                 target => $self->target,
                                 class => $self->class );
    } else {
        return _( $self->label );
    }
}

1;
