package TestApp::Action::DoSomethingElse;

use Jifty::Param::Schema;
use Jifty::Action schema {

param foo =>
    label is 'Foo',
    ajax validates,
    is mandatory;

param bar =>
    label is 'Bar',
    ajax validates,
    is mandatory;
};

sub take_action {
    my $self = shift;
    $self->result->message("Something happened!");
}

1;
