package Jifty::Server::Fork::NetServer;

use base 'Net::Server::Fork';

=head1 NAME

Jifty::Server::Fork::NetServer - Sets up children for Jifty::Server::Fork

=head1 METHODS

=head2 post_accept_hook

After forking every connection, resetup the database connections so we
don't share them with our parent.

=cut

sub post_accept_hook {
    Jifty->setup_database_connection();
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
