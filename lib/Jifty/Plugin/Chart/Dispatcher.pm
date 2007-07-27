use strict;
use warnings;

package Jifty::Plugin::Chart::Dispatcher;
use Jifty::Dispatcher -base;

use Jifty::YAML;

on 'chart/*' => run {
    my $session_id = 'chart_' . $1;

    my $args = Jifty::YAML::Load( Jifty->web->session->get( $session_id ) );
    Jifty->web->session->remove( $session_id );

    last_rule unless defined $args;

    set 'args' => $args;
    show 'chart';
};

1;
