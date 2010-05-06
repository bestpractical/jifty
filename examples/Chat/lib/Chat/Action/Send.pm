package Chat::Action::Send;
use warnings;
use strict;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param message =>
        label is 'Say something witty:';
};

sub take_action {
    my $self = shift;
    my $msg  = $self->argument_value('message');
    $msg = "<$1\@".Jifty->web->request->address."> $msg" if Jifty->web->request->user_agent =~ /([^\W\d]+)[\W\d]*$/;
    Chat::Event::Message->new( { message => $msg } )->publish;
}

1;
