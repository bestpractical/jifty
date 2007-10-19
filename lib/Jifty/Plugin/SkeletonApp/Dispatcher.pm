use warnings;
use strict;

package Jifty::Plugin::SkeletonApp::Dispatcher;

=head1 NAME

Jifty::Plugin::SkeletonApp::Dispatcher

=head1 DESCRIPTION

When a user asks for /, give them index.html.

=cut


use Jifty::Dispatcher -base;

    

on '**' => run {
    my $top = Jifty->web->navigation;

    # Do not override the 'Home' menu item if the app had set it already
    unless ( $top->child('Home') ) {
        $top->child( Home => url => "/", sort_order => 1, label => _('Home') );
    }

    if ( Jifty->config->framework('AdminMode') ) {
        $top->child(
            Administration =>
              url          => "/__jifty/admin/",
            label      => _('Administration'),
            sort_order => 998
        );
    }
    return ();
};

before '**' => run {
    if (my $lang = Jifty->web->request->arguments->{_jifty_lang}) {
        Jifty->web->session->set(jifty_lang => $lang);
    }
};

1;
