use warnings;
use strict;

package Jifty::Plugin::AdminUI::Dispatcher;

=head1 NAME

Jifty::Plugin::AdminUI::Dispatcher - dispatcher of the AdminUI plugin

=head1 DESCRIPTION

Adds dispatching rules required for the AdminUI plugin.

=cut

use Jifty::Dispatcher -base;

=head1 RULES

=head2 on '**'

Adds 'Administration' item to the top navigation if AdminMode is activated in the config.

=cut

on '**' => run {
    my $top = Jifty->web->navigation;
    # for now leave check here, but we want AdminUI to be
    # real plugin someday
    if (Jifty->admin_mode) {
        $top->child(
            Administration =>
            url        => "/__jifty/admin/",
            label      => _('Administration'),
            sort_order => 998,
        );
    }
    return ();
};

1;
