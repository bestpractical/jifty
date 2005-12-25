use warnings;
use strict;


package Jifty::Test;

=head2 setup

Loads up application specific test modules

=cut

sub setup {
    Jifty->new( config_file => 'etc/config.yml' );
    my $test_class = Jifty->config->framework('ApplicationClass') . "::Test";
    $test_class->require;

    unless ($UNIVERSAL::require::ERROR) {
        $test_class->setup_test;
    }
    return 1;
}

=head2 make_server

Loads the config file, creates a new L<Jifty::Server>, and calls
C<< I<ApplicationClass>::Test->setup_test >>.

=cut

sub make_server {

    Jifty::Test->setup();

    require Test::HTTP::Server::Simple;
    unshift @Jifty::Server::ISA, 'Test::HTTP::Server::Simple';

    my $server = Jifty::Server->new;

    return $server;
} 

1;
