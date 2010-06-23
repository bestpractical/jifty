package Jifty::Plugin::TestServerWarnings::Appender;
use strict;
use warnings;
use base qw/Log::Log4perl::Appender/;

=head1 NAME

Jifty::Plugin::TestServerWarnings::Appender - Log appender

=head1 DESCRIPTION

L<Log::Log4perl::Appender> which stores warnings in memory, for later
downloading by the test client.

=head1 METHODS

=head2 new

Creates a new appender; takes no arguments.

=cut

sub new {
    my $class = shift;
    return bless {@_}, $class;
}

=head2 log

Appends the message to L<Jifty::Plugin::TestServerWarnings>' internal
storage.

=cut

sub log {
    my $self = shift;
    my %params = @_;
    my $plugin = Jifty->find_plugin("Jifty::Plugin::TestServerWarnings");
    my $message = $params{message};
    $message = join('',@{$message}) if ref $message eq "ARRAY";
    $plugin->add_warnings($message);
}

1;
