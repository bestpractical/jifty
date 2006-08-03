use warnings;
use strict;

package Jifty::Test;
use base qw/Test::More/;

use Jifty::Server;
use Jifty::Script::Schema;
use Email::LocalDelivery;
use Email::Folder;
use File::Path;

=head2 import_extra

Called by L<Test::More>'s C<import> code when L<Jifty::Test> is first
C<use>'d, it calls L</setup>, and asks Test::More to export its
symbols to the namespace that C<use>'d this one.

=cut

sub import_extra {
    my $class = shift;
    $class->setup;
    Test::More->export_to_level(2);
}

=head2 setup

Merges the L</test_config> into the default configuration, resets the
database, and resets the fake "outgoing mail" folder.  This is the
method to override if you wish to do custom setup work, such as insert
test data into your database.

=cut

sub setup {
    my $class = shift;

    my $test_config = File::Temp->new( UNLINK => 0 );
    Jifty::YAML::DumpFile($test_config, $class->test_config(Jifty::Config->new));
    # Invoking bin/jifty and friends will now have the test config ready.
    $ENV{'JIFTY_TEST_CONFIG'} ||= $test_config;
    Jifty::Test->builder->{test_config} = $test_config;
    {
        # Cache::Memcached stores things. And doesn't let them
        # expire from the cache easily. This is fine in production,
        # but during testing each test script needs its own namespace.
        # we use the pid.

        no warnings qw/redefine/;
    
        sub Jifty::Record::cache_key_prefix {
            'jifty-test-' . $$;
        }
    }
    my $root = Jifty::Util->app_root;

    # Mason's disk caching sometimes causes false tests
    rmtree(["$root/var/mason"], 0, 1);

    Jifty->new( no_handle => 1 );

    Log::Log4perl->get_logger("SchemaTool")->less_logging(3);
    my $schema = Jifty::Script::Schema->new;
    $schema->{drop_database} =
      $schema->{create_database} =
        $schema->{create_all_tables} = 1;
    $schema->run;
    Log::Log4perl->get_logger("SchemaTool")->more_logging(3);

    Jifty->new();
    $class->setup_mailbox;
}

=head2 test_config

Returns a hash which overrides parts of the application's
configuration for testing.  By default, this changes the database name
by appending a 'test', as well as setting the port to a random port
between 10000 and 15000.

It is passed the current configuration.

You can override this to provide application-specific test
configuration, e.g:

    sub test_config {
        my $class = shift;
        my ($config) = @_;
        my $hash = $class->SUPER::test_config($config);
        $hash->{framework}{LogConfig} = "etc/log-test.conf"
    
        return $hash;
    }

=cut

sub test_config {
    my $class = shift;
    my ($config) = @_;

    return {
        framework => {
            Database => {
                Database => $config->framework('Database')->{Database} . "test",
            },
            Web => {
                Port => int(rand(5000) + 10000),
            },
            Mailer => 'Jifty::Test',
            MailerArgs => [],
        }
    };
}

=head2 make_server

Creates a new L<Jifty::Server> which C<ISA> L<Jifty::TestServer> and
returns it.

=cut

sub make_server {
    my $class = shift;

    # XXX: Jifty::TestServer is not a Jifty::Server, it is actually
    # server controller that invokes bin/jifty server. kill the
    # unshift here once we fix all the tests expecting it to be
    # jifty::server.
    if ($ENV{JIFTY_TESTSERVER_PROFILE} ||
        $ENV{JIFTY_TESTSERVER_COVERAGE} ||
        $ENV{JIFTY_TESTSERVER_DBIPROF}) {
        require Jifty::TestServer;
        unshift @Jifty::Server::ISA, 'Jifty::TestServer';
    }
    else {
        require Test::HTTP::Server::Simple;
        unshift @Jifty::Server::ISA, 'Test::HTTP::Server::Simple';
    }

    Log::Log4perl->get_logger("Jifty::Server")->less_logging(3);
    my $server = Jifty::Server->new;

    return $server;
} 

=head2 mailbox

A mailbox used for testing mail sending.

=cut

sub mailbox {
    return Jifty::Util->absolute_path("t/mailbox");
}

=head2 setup_mailbox

Clears the mailbox.

=cut

sub setup_mailbox {
    open my $f, ">", mailbox();
    close $f;
} 

=head2 is_available

Informs L<Email::Send> that L<Jifty::Test> is always available as a mailer.

=cut

sub is_available { 1 }

=head2 send

Should not be called manually, but is
automatically called by L<Email::Send> when using L<Jifty::Test> as a mailer.

(Note that it is a class method.)

=cut

sub send {
    my $class = shift;
    my $message = shift;

    Email::LocalDelivery->deliver($message->as_string, mailbox());
}

=head2 messages

Returns the messages in the test mailbox, as a list of
L<Email::Simple> objects.  You may have to use a module like
L<Email::MIME> to parse multi-part messages stored in the mailbox.

=cut

sub messages {
    return Email::Folder->new(mailbox())->messages;
} 

END {
    my $Test = Jifty::Test->builder;
    # Such a hack -- try to detect if this is a forked copy and don't
    # do cleanup in that case.
    return if $Test->{Original_Pid} != $$;

    # If all tests passed..
    unless ($Test->expected_tests != $Test->current_test or grep {not $_} $Test->summary) {
        # Clean up mailbox
        unlink mailbox();

        # Remove testing db
        if (Jifty->handle) {
            Jifty->handle->disconnect();
            Log::Log4perl->get_logger("SchemaTool")->less_logging(3);
            my $schema = Jifty::Script::Schema->new;
            $schema->{drop_database} = 1;
            $schema->run;
            Log::Log4perl->get_logger("SchemaTool")->more_logging(3);
        }
    }

    # Unlink test file
    unlink $Test->{test_config} if $Test->{test_config};
}

1;
