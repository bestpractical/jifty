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

template '__jifty/empty' => sub {
        '';
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

1;
