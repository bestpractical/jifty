use strict;
use warnings;

package Jifty::Plugin::Chart::Web;

sub chart {
    my $self = shift;
    my ($plugin) = Jifty->find_plugin('Jifty::Plugin::Chart');
    return $plugin->render(@_);
}

1;
