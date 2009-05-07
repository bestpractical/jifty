package Jifty::Server::Fork::NetServer;

use base 'Net::Server::Fork';

=head1 NAME

Jifty::Server::Fork::NetServer - Sets up children for Jifty::Server::Fork

=head1 METHODS

=head2 new

Store the created L<Net::Server::Fork> object away after creating it.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $Jifty::SERVER->{net_server} = $self;
    return $self;
}

=head2 pre_loop_hook

Tear down the database connection before falling into the accept loop,
so that there is no shared database connection for children to
inherit.

=cut

sub pre_loop_hook {
    Jifty->handle(undef);
}

=head2 post_accept_hook

After forking every connection, resetup the database connections.

=cut

sub post_accept_hook {
    Jifty->setup_database_connection;
}

=head2 log

Log messages should use Jifty's L<Log::Log4perl> infrastructure, not
STDERR.

=cut

sub log {
    my $self = shift;
    my ($level, $msg) = @_;
    chomp $msg;
    my @levels = (
        $Log::Log4perl::FATAL,
        $Log::Log4perl::WARN,
        $Log::Log4perl::INFO,
        $Log::Log4perl::DEBUG,
        $Log::Log4perl::TRACE,
        $Log::Log4perl::TRACE,
    );
    $Log::Log4perl::caller_depth++;
    Log::Log4perl->get_logger(ref $self)->log($levels[$level],$msg);
    $Log::Log4perl::caller_depth--;
}

1;
