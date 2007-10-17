package TestApp::Action::SayHi;

use Jifty::Param::Schema;
use Jifty::Action schema {

    param 'name';
    param 'greeting';


};

sub take_action {
    my $self = shift;

    $self->result->message($self->argument_value('name').', '. $self->argument_value('greeting'));
}

1;
