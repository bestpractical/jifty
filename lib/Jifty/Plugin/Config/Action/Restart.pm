package Jifty::Plugin::Config::Action::Restart;
use strict;
use warnings;

use base qw/Jifty::Action/;

=head2 NAME

Jifty::Plugin::Config::Action::Restart - Restart action

=cut


=head2 arguments

=cut

sub arguments {
    return {};
}

=head2 take_action

=cut

sub take_action {
    my $self = shift;
    Jifty->web->tangent( url => Jifty::Plugin::Config->restart_url . '?url=/' );
    return 1;
}

1;

