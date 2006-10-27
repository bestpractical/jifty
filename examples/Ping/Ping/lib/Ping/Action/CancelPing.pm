package Ping::Action::CancelPing;
use strict;
use Jifty::Param::Schema;
use Jifty::Action schema {

param host =>
    label is 'Hostname',
    is mandatory;

};

sub take_action {
    my $self = shift;
    my $host = $self->argument_value('host');

    my $id  = Jifty->web->session->id;
    my $sid = Jifty->bus->modify("$id-ping" => sub {
        delete($_->{$host})
    });
    Jifty->subs->cancel($sid);

    $self->result->message( "Cancelled host: $host" );
}

1;
