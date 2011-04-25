package Ping::PingServer;

use Net::Ping;
use Time::HiRes qw( time sleep );
use Jifty;

BEGIN { Jifty->new };

sub ping {
    my ($class, $host) = @_;
    my $ping = Net::Ping->new(tcp => 1);
    while (1) {
        my $old_time = time;
        my $alive = $ping->ping($host);
        my $new_time = time;

        Ping::Event::Pong->new(
            { host => $host, alive => ($alive ? ($new_time - $old_time + 0.001) : 0), time => $new_time }
        )->publish;
        sleep 1;
    }
    exit;
}

1;
