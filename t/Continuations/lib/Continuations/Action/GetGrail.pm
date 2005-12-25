package Continuations::Action::GetGrail;

use base qw/Jifty::Action/;

sub take_action {
    my $self = shift;

    $self->result->message("You got the grail!");
}

1;
