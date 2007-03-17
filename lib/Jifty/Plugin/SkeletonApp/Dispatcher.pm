use warnings;
use strict;

package Jifty::Plugin::SkeletonApp::Dispatcher;

=head1 NAME

Jifty::Plugin::SkeletonApp::Dispatcher

=head1 DESCRIPTION

When a user asks for /, give them index.html.

=cut


use Jifty::Dispatcher -base;

    

on '*' => run {
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


1;
