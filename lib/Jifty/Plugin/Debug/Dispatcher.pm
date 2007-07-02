use warnings;
use strict;

package Jifty::Plugin::Debug::Dispatcher;
use Jifty::Dispatcher -base;

=head1 NAME

Jifty::Plugin::Debug::Dispatcher - dispatcher for the debug plugin

=head1 DESCRIPTION

This adds a debugging rule to record debugging information about every request.

=head1 RULES

=head2 on qr'(.*)'

Records the request. The INFO level log message recorded contains the PID of the current process, the URL requested, and the username (if any) attached to the current session.

=cut

on qr'(.*)' => run {
    Jifty->log->info("[$$] $1 ".(Jifty->web->current_user->id ? Jifty->web->current_user->username : ''));
};

1;

