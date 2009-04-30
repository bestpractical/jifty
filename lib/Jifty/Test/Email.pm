use warnings;
use strict;

package Jifty::Test::Email;
use Test::More;
use Test::Email;
use Email::Abstract;

use base 'Exporter';
our @EXPORT = qw(mail_ok);

=head1 NAME

Jifty::Test::Email - Test mail notification

=head1 SYNOPSIS

  use Jifty::Test::Email;

  mail_ok {
    # ... code
  } { from => 'admin@localhost', body => qr('hello') },
    { from => 'admin@localhost', body => qr('hello again') };

  # ... more code

  # XXX: not yet
  mail_sent_ok { from => 'admin@localhost', body => qr('hello') };

  # you should expect all mails by the end of the test


=head1 DESCRIPTION

This is a test helper module for jifty, allowing you to expect mail
notification generated during the block or the test.

=head1 METHODS

=head2 mail_ok BLOCK HASHREF [, HASHREF ...]

Executes the C<BLOCK>, and expects it to send a number of emails equal
to the number of C<HASHREF>s after the C<BLOCK>.  L<Test::Email/ok> is
used to check if the messages match up to the appropriate hashrefs.

=cut

sub mail_ok (&@) {
    my $code = shift;
    # XXX. ensure mailbox is empty; but make sure the test count is correct
    $code->();
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my @msgs = Jifty::Test->messages;
    is(@msgs, @_, "Sent exactly " . @_ . " emails");

    for my $spec (@_) {
        my $msg = shift @msgs
            or ok(0, 'Expecting message but none found.'), next;

        my $te = Email::Abstract->new($msg)->cast('MIME::Entity');
        bless $te, 'Test::Email';
        $te->ok($spec, "email matched") or diag $msg->as_string;
    }
    Jifty::Test->setup_mailbox;
}

=head1 ENDING TESTS

An END block causes the test to C<die> if there are uncaught
notifications at the end of the test script.

=cut

END {
    my $Test = Jifty::Test->builder;
    # Such a hack -- try to detect if this is a forked copy and don't
    # do cleanup in that case.
    return if $Test->{Original_Pid} != $$;

    if (scalar Jifty::Test->messages) {
        diag ((scalar Jifty::Test->messages)." uncaught notification email at end of test: ");
        diag "From: @{[ $_->header('From' ) ]}, Subject: @{[ $_->header('Subject') ]}"
            for Jifty::Test->messages;
        die;
    }
}

1;

