package Chat::Action::Send;
use warnings;
use strict;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param message => label is 'Say something witty:', type is 'text';
};

sub take_action {
    my $self = shift;
    Chat::Event::Message->new( { message => $self->argument_value('message') } )->publish;
}
1;
