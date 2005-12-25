use warnings;
use strict;


package JFDI::Test;

=head2 setup

Loads up application specific test modules

=cut

sub setup {
    JFDI->new( config_file => 'etc/config.yml' );
    my $test_class = JFDI->framework_config('ApplicationClass') . "::Test";
    $test_class->require;

    unless ($UNIVERSAL::require::ERROR) {
        $test_class->setup_test;
    }
    return 1;
}

=head2 make_server

Loads the config file, creates a new L<JFDI::Server>, and calls
C<< I<ApplicationClass>::Test->setup_test >>.

=cut

sub make_server {

    JFDI::Test->setup();

    require Test::HTTP::Server::Simple;
    unshift @JFDI::Server::ISA, 'Test::HTTP::Server::Simple';

    my $server = JFDI::Server->new;

    return $server;
} 

1;
