#!/usr/bin/env perl
use warnings;
use strict;

BEGIN {
    #### XXX: I know this is foolish but right now Jifty on Win32 fails to 
    #### unlink used test databases and the following tests fail saying
    #### 'error creating a table... table already exists'. So, remove the
    #### remnant first. And we should do it before none of the Jifty is there.

    my $testdb = 't/TestApp/testapptest';
    if (-e $testdb) {
        unlink $testdb or die $!;
    }
}

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 13;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::Server');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok("$URL/__jifty/validator.xml?J:A-dosomething=TestApp::Action::DoSomething&J:A:F-email-dosomething=good\@address.com&J:VALIDATE=1&_=",
    "Getting validator.xml output for valid form entry");
$mech->content_contains('<ok id="errors-J:A:F-email-dosomething" />',
    " ... validator returned ok for errors");
$mech->content_contains('<ok id="warnings-J:A:F-email-dosomething" />',
    " ... validator returned ok for warnings");

$mech->get_ok("$URL/__jifty/validator.xml?J:A-dosomething=TestApp::Action::DoSomething&J:A:F-email-dosomething=warn\@email.com&J:VALIDATE=1&_=",
    "Getting validator.xml output for a warning form entry");
$mech->content_contains('<ok id="errors-J:A:F-email-dosomething" />',
    " ... validator returned ok for errors");
$mech->content_contains('<warning id="warnings-J:A:F-email-dosomething">Warning for email</warning>',
    " ... validator returned warning");

$mech->get_ok("$URL/__jifty/validator.xml?J:A-dosomething=TestApp::Action::DoSomething&J:A:F-email-dosomething=bad\@email.com&J:VALIDATE=1&_=",
    "Getting validator.xml output for a warning form entry");
$mech->content_contains('<error id="errors-J:A:F-email-dosomething">Bad looking email</error>',
    " ... validator returned error");
$mech->content_contains('<ok id="warnings-J:A:F-email-dosomething" />',
    " ... validator returned ok for warnings");

$mech->get_ok("$URL/__jifty/validator.xml?J:A-dosomething=TestApp::Action::DoSomething&J:A:F-email-dosomething=UPPER\@EMAIL.com&J:VALIDATE=1&_=",
    "Getting validator.xml output for a canonicalization");
$mech->content_contains('<update name="J:A:F-email-dosomething">upper@email.com</update>',
    " ... canonicalizer returned all lower case (good)");

