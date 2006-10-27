package Chat::Action::Send;
use warnings;
use strict;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param message => label is 'Say something witty:', type is 'text';
};

sub take_action {
    my $self = shift;
    my $msg  = $self->argument_value('message');
    $msg = "<$1> $msg" if $ENV{HTTP_USER_AGENT} =~ /([^\W\d]+)[\W\d]*$/;
    Chat::Event::Message->new( { message => $msg } )->publish;
}

1;
