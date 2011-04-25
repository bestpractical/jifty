use strict;
use lib 'lib';
use Time::HiRes qw/ time sleep /;
use Jifty;

BEGIN { Jifty->new };

sub ping {
    my ($class, $sub) = @_;
    while (1) {
        my $new_time = time;
        warn "Time: $new_time\n";
        Clock::Event::Tick->new($new_time)->publish;
        sleep 0.5;
    }
    exit;
}

ping();

1;
