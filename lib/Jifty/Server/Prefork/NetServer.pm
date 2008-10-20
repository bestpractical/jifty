package Jifty::Server::Prefork::NetServer;

use base 'Net::Server::PreFork';

=head1 NAME

Jifty::Server::Prefork::NetServer - Sets up children for Jifty::Server::Prefork

=head1 METHODS

=head2 child_init_hook

Sets up the database connection when spawning a new child

=cut

sub child_init_hook {
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
