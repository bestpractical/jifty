use warnings;
use strict;

package Jifty::Plugin::OnlineDocs::Dispatcher;

=head1 NAME

Jifty::Plugin::OnlineDocs::Dispatcher - Dispatcher for OnlineDocs plugin

=head1 DESCRIPTION

Load up the OnlineDocs tab when we're in Admin mode

=cut

use Jifty::Dispatcher -base;
    
on '*' => run {
    return unless Jifty->config->framework('AdminMode');

    my $top = Jifty->web->navigation;
    $top->child(
        "OnlineDocs",
        url        => "/__jifty/online_docs/",
        label      => _('Online docs'),
        sort_order => 999
    );
};

under '/__jifty/online_docs' => run {
    return if Jifty->config->framework('AdminMode');
    warn "Attempt to access /__jifty/online_docs; either enable AdminMode, or remove the OnlineDocs plugin";
    redirect('/__jifty/error/permission_denied');
};

1;

