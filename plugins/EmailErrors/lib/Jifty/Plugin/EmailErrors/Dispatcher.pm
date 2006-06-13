use strict;
use warnings;

package Jifty::Plugin::EmailErrors::Dispatcher;
use Jifty::Dispatcher -base;

after '/__jifty/error/mason_internal_error', run {
    return if already_run;
    return unless Jifty->web->request->continuation;
    Jifty::Plugin::EmailErrors::Notification::EmailError->new->send;
};

1;
