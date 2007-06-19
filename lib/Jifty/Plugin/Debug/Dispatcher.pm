use warnings;
use strict;

package Jifty::Plugin::Debug::Dispatcher;
use Jifty::Dispatcher -base;

on qr'(.*)' => run {
    Jifty->log->debug("[$$] $1 ".(Jifty->web->current_user->id ? Jifty->web->current_user->username : ''));
};

1;

