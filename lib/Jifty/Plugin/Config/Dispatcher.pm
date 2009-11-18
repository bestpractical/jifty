use warnings;
use strict;

package Jifty::Plugin::Config::Dispatcher;

=head1 NAME

Jifty::Plugin::Config::Dispatcher - dispatcher of the Config plugin

=head1 DESCRIPTION

Adds dispatching rules required for the Config plugin.

=cut

use Jifty::Dispatcher -base;

=head1 RULES

=head2 on '**'

Adds 'Configuration' item to the top navigation

=cut

on '**' => run {
    my ($plugin) = Jifty->find_plugin('Jifty::Plugin::Config') or return;
    return unless $plugin->nav_menu;

    my $top = Jifty->web->navigation;

    # for now leave check here, but we want Config to be
    # real plugin someday
    $top->child(
        Configuration => url => Jifty::Plugin::Config->config_url,
        label         => _('Configuration'),
        sort_order    => 990,
    );
    return ();
};

before '*' => run {
    Jifty->api->allow('Jifty::Plugin::Config::Action::AddConfig');
    Jifty->api->allow('Jifty::Plugin::Config::Action::Config');
    Jifty->api->allow('Jifty::Plugin::Config::Action::Restart');
};

1;
