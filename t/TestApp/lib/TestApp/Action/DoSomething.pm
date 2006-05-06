package TestApp::Action::DoSomething;

use base qw/Jifty::Action/;

sub take_action {
    my $self = shift;

    $self->result->message("Something happened!");
}

1;
