package Ping::Action::AddPing;
use strict;
use Jifty::Param::Schema;
use Jifty::Action schema {

param host =>
    label is 'Hostname',
    is mandatory;

param only_failure =>
    type is 'checkbox',
    label is 'Failure only?',
    hints is 'Show only failed pings to me.',
    default is 0;

};

sub take_action {
    my $self = shift;
    my $host = $self->argument_value('host');
    my $only_failure = $self->argument_value('only_failure');

    Jifty->bus->modify(hosts => sub {
        $_->{$host} ||= do {
            if (my $pid = fork) {
                $pid;
            }
            else {
                exec($^X => "-Ilib", "-MPing::PingServer", "-e", "Ping::PingServer->ping('$host')");
            }
        }
    });

    my $id = Jifty->web->session->id;

    Jifty->bus->modify("$id-ping" => sub {
        my $sid = $_->{$host}; 
        Jifty->subs->cancel($sid) if $sid;
        $_->{$host} = Jifty->subs->add(
            class       => 'Pong',
            queries     => [{ host => $host }, $only_failure ? { fail => 1 } : ()],
            mode        => 'Bottom',
            region      => 'pong',
            render_with => '/fragments/pong',
        );
    });

    $self->result->message( "Added host: $host" );
}

1;
