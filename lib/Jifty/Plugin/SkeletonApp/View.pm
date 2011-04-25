package Jifty::Plugin::SkeletonApp::View;

use strict;
use warnings;

use Jifty::View::Declare -base;

use Scalar::Defer;

=head1 NAME

Jifty::Plugin::SkeletonApp::View - Default fragments for your pages

=head1 DESCRIPTION

This somewhat-finished (But not quite) template library implements
Jifty's "pony" Application. It could certainly use some
refactoring. (And some of the menu stuff should get factored out into
a dispatcher or the other plugins that implement it.


=cut

private template 'salutation' => sub {
    my $cu = Jifty->web->current_user;
    div {
    attr {id => "salutation" };
        if ( $cu->id and $cu->user_object ) {
            _( 'Hiya, %1.', $cu->username );
        }
        else {
            _("You're not currently signed in.");
        }
    }
};

private template 'menu' => sub {
    div { attr { id => "navigation" };
        Jifty->web->navigation->render_as_menu;
    };
};

template '__jifty/empty' => sub :Static {
        '';
};


private template 'header' => sub {
    my ($title) = get_current_attr(qw/title/);
    Jifty->web->response->content_type('text/html; charset=utf-8');
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
    };
};

private template 'heading_in_wrapper' => sub {
    h1 { attr { class => 'title' }; outs_raw(get('title')) };
};

private template 'keybindings' => sub {
    div { id is "keybindings" };
};

#template 'index.html' => page { { title is _('Welcome to your new Jifty application') } img { src is "/static/images/pony.jpg", alt is _( 'You said you wanted a pony. (Source %1)', 'http://hdl.loc.gov/loc.pnp/cph.3c13461'); }; };

1;
