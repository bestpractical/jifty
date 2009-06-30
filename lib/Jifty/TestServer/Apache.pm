package Jifty::TestServer::Apache;

use strict;
use warnings;
use File::Spec;
use Test::Builder;

# explicitly ignore ClassLoader objects in @INC,
# which'd be ignored in the end, though.
my $INC = [grep { defined } map { File::Spec->rel2abs($_) } grep { !ref } @INC ];

=head1 NAME

Jifty::TestServer::Apache - Starting and stopping an apache server for tests

=head1 DESCRIPTION

=head1 METHOD

=head2 started_ok

Like started_ok in C<Test::HTTP::Server::Simple>, start the server and
return the URL.

=cut

sub started_ok {
    my $self = shift;
    my $text = shift;
    $text = 'started server' unless defined $text;

    $self->{pidfile} = File::Temp->new;
    close $self->{pidfile};
    $self->{pidfile} .= "";
    my $ipc = File::Temp::tempdir( CLEANUP => 1 );
    my $errorlog = File::Temp->new;
    my $config = File::Temp->new;

    my $PATH = Jifty::Util->absolute_path("bin/jifty");
    my $STATIC = Jifty::Util->absolute_path(Jifty->config->framework('Web')->{StaticRoot});

    print $config <<"CONFIG";
ServerName 127.0.0.1
Port @{[$self->port]}
User @{[scalar getpwuid($<)]}
Group @{[scalar getgrgid($()]}
MinSpareServers 1
StartServers 1
PidFile @{[$self->{pidfile}]}
ErrorLog $errorlog
<Location />
    Options FollowSymLinks ExecCGI
</Location>
FastCgiIpcDir $ipc
FastCgiServer $PATH -initial-env JIFTY_COMMAND=fastcgi  -idle-timeout 300  -processes 1 -initial-env PERL5LIB=@{[join(":",@{$INC})]}
ScriptAlias  / $PATH/
Alias /static/ $STATIC/
CONFIG
    close $config;

    if (fork()) {
        my $pid;
        for (1..15) {
            last if $pid = $self->pids;
            sleep 1;
        }
        my $Tester = Test::Builder->new;
        if ($pid) {
            $self->{started} = 1;
            $Tester->ok(1, $text);
            return "http://localhost:".$self->port;
        } else {
            $Tester->ok(0, $text);
            return "";
        }
    }

    exec($ENV{JIFTY_APACHETEST}, "-f", $config);
}

=head2 pids

Returns the process ID of the Apache server.

=cut

sub pids {
    my $self = shift;
    return unless -e $self->{pidfile};
    my $pid = do {local @ARGV = ($self->{pidfile}); scalar <>};
    chomp $pid;
    return ($pid);
}

sub DESTROY {
    return unless $_[0]->{started};
    my($pid) = $_[0]->pids;
    kill(15, $pid) if $pid;
    1 while ($_ = wait()) >= 0;
    sleep 1 while kill(0, $pid);
}

1;
