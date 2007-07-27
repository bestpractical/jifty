use strict;
use warnings;

package Jifty::Plugin::Chart::Renderer::Chart;
use base qw/ Jifty::Plugin::Chart::Renderer /;

use Jifty::YAML;

sub render {
    my $self = shift;
    my %args = (
        type   => 'points',
        width  => 400,
        height => 300,
        data   => [],
        @_,
    );

    for my $key (keys %args) {
        $args{$key} = $args{$key}->(\%args) if ref $args{$key} eq 'CODE';
    }

    my $chart_id   = Jifty->web->serial;
    my $session_id = 'chart_' . $chart_id;
    Jifty->web->session->set( $session_id => Jifty::YAML::Dump(\%args) );

    Jifty->web->out(qq{<img src="/chart/$chart_id" width="$args{width}" height="$args{height}"/>});

    return;
}

1;
