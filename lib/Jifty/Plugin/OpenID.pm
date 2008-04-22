use strict;
use warnings;

package Jifty::Plugin::OpenID;
use base qw/Jifty::Plugin/;
use LWPx::ParanoidAgent;

=head1 NAME

Jifty::Plugin::OpenID

=head1 DESCRIPTION

Provides OpenID authentication for your app

=cut

sub get_csr {
    my $class = shift;

    return Net::OpenID::Consumer->new(
        ua              => LWPx::ParanoidAgent->new,
        cache           => Cache::FileCache->new,
        args            => scalar Jifty->handler->cgi->Vars,
        consumer_secret => Jifty->config->app('OpenIDSecret'),
        @_,
    );
}

1;
