package Jifty::MasonHandler;
use base qw/HTML::Mason::CGIHandler/;

sub request_args {
    return %{Jifty->web->request->arguments};
}

package Jifty::MasonRequest;
use base qw/HTML::Mason::Request::CGI/;

sub auto_send_headers {
    return not Jifty->web->request->is_subrequest;
}

1;
