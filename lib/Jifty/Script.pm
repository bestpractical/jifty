package Jifty::Script;
use base qw/App::CLI/;

sub alias {
    return (
            server  => "StandaloneServer",
            fastcgi => "FastCGI",
           )
}

1;
