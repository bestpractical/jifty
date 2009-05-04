package Jifty::Plugin::Config::View;
use strict;
use warnings;

use Jifty::View::Declare -base;

__PACKAGE__->use_mason_wrapper;
my $config_url = Jifty::Plugin::Config->config_url;
my $restart_url = Jifty::Plugin::Config->restart_url;
template $config_url => sub {
    my $config = new_action( class => 'Config' );
    form {
        render_action( $config );
        form_next_page( url => '/__jifty/config/restart.html' );
        form_submit( label => _('Save and Restart') );
    }
};

template $restart_url => sub {
    my $seconds = get('seconds') || Jifty::Plugin::Config->wait_seconds || 5;
    my $url = get('url') || Jifty::Plugin::Config->after_restart_url;
    $url =
        Jifty->config->framework('Web')->{BaseURL} . ':'
      . Jifty->config->framework('Web')->{Port}
      . $url
      unless $url =~ /^https?:/;
    outs_raw(<<"EOF");
<html>
<head>
<title>restarting</title>
<meta http-equiv="refresh" content="$seconds;url=$url" />
</head>
<body>
<h1>please wait for $seconds seconds so the server can restart,
    then we'll redirect to <a href="$url">here</a></h1>
</body>
</html>
EOF

    Jifty->handler->buffer->flush_output();
    $Jifty::SERVER->restart;
};
