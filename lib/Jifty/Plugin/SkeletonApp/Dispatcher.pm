use warnings;
use strict;

package Jifty::Plugin::SkeletonApp::Dispatcher;

=head1 NAME

Jifty::Plugin::SkeletonApp::Dispatcher

=head1 DESCRIPTION

Elementary things for a basic app.

=cut

use Jifty::Dispatcher -base;

=head1 RULES

=head2 on '**'

Add 'Home' item to the top navigation unless it's there already.

=cut

on '**' => run {
    my $top = Jifty->web->navigation;

    # Do not override the 'Home' menu item if the app had set it already
    unless ( $top->child('Home') ) {
        $top->child( Home => url => "/", sort_order => 1, label => _('Home') );
    }
    return ();
};

=head2 before '**'

Sets language of the current session if the request has '_jifty_lang' argument.

=cut

before '**' => run {
    if (my $lang = Jifty->web->request->arguments->{_jifty_lang}) {
        Jifty->web->session->set(jifty_lang => $lang);
    }
};

1;
