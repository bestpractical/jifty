#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Test the interactions between continuations and dispatcher BEFORE
blocks

=cut

BEGIN {
    #### XXX: I know this is foolish but right now Jifty on Win32 fails to 
    #### unlink used test databases and the following tests fail saying
    #### 'error creating a table... table already exists'. So, remove the
    #### remnant first. And we should do it before none of the Jifty is there.

    my $testdb = 't/Continuations/continuationstest';
    if (-e $testdb) {
        unlink $testdb or die $!;
    }
}

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 9;

use_ok('Jifty::Test::WWW::Mechanize');

my $server = Jifty::Test->make_server;
my $URL = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new;

$mech->get($URL . '/tutorial');
like($mech->uri, qr'index-help\.html', '/tutorial redirected to /index-help.html');
$mech->follow_link_ok(text => 'Done');
like($mech->uri, qr'/tutorial', 'Continuation call worked properly');
$mech->content_contains('Congratulations', 'before blocks got run properly on continuation call');
$mech->content_contains('being helped: 1', 'before blocks got run only once');

$mech->get($URL . '/tutorial');
$mech->content_contains('Congratulations', 'before blocks got run properly');
$mech->content_contains('being helped: 2', 'before blocks got run only once again');

1;

