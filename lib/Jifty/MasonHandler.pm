package Jifty::MasonHandler;
use base qw/HTML::Mason::CGIHandler/;

sub request_args {
    return %{Jifty->web->request->arguments};
}

1;
