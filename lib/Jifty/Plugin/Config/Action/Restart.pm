package Jifty::Plugin::Config::Action::Restart;
use strict;
use warnings;

use base qw/Jifty::Action/;

=head2 NAME

Jifty::Plugin::Config::Action::Restart - Restart action

=cut

use Jifty::Param::Schema;
use Jifty::Action schema {
    param 'url' =>
        render as 'hidden';
};

=head2 take_action

=cut

sub take_action {
    my $self = shift;
    Jifty->web->tangent(
        url => Jifty::Plugin::Config->restart_url . '?url='
          . (
            $self->argument_value('url')
              || Jifty::Plugin::Config->after_restart_url
          )
    );
    return 1;
}

1;

