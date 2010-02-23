#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 27;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::TestServer');

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
$mech->content_contains('<canonicalization_note id="canonicalization_note-J:A:F-email-dosomething">Lowercased your email</canonicalization_note>',
    " ... canonicalizer warned user");

$mech->get_ok("$URL/dosomethingelse");
$mech->fill_in_action_ok('dosomething',
    'foo' => 'something',
    'bar' => '',
);
$mech->submit_html_ok();
$mech->content_contains('<span class="error text argument-bar" id="errors-J:A:F-bar-dosomething">You need to fill in the \'Bar\' field</span>', 'got error for bar');
$mech->content_contains('<span class="error text argument-foo" id="errors-J:A:F-foo-dosomething"></span>', 'got no error for foo');

$mech->get_ok("$URL/__jifty/validator.xml?J:A-dosomething=TestApp::Action::DoSomethingElse&J:A:F-foo-dosomething=&J:A:F-bar-dosomething=blam&J:VALIDATE=1&_=",
    "Getting validator.xml output for a form entry");
$mech->content_lacks('<error id="errors-J:A:F-bar-dosomething">', " ... validator didn't return error for bar");

$mech->get_ok("$URL/__jifty/validator.xml?J:A-canontest=TestApp::Action::CreateCanonTest&J:A:F-column_1-canontest=f-f&J:VALIDATE=1",
    "Getting validator.xml output for a form entry to check canonicalize_");
$mech->content_contains('<update name="J:A:F-column_1-canontest">ff</update>');

$mech->get_ok("$URL/__jifty/validator.xml?J:A-canontest=TestApp::Action::CreateCanonTest&J:A:F-column_1-canontest=%3Bf&J:VALIDATE=1",
    "Getting validator.xml output for a form entry to check canonicalize_");
$mech->content_lacks('<ignored name="J:A:F-column_1-canontest"');
$mech->content_contains('<update name="J:A:F-column_1-canontest">f</update>');

TODO: {
local $TODO = "Not implemented in Jifty yet";
$mech->content_contains('<error id="errors-J:A:F-foo-dosomething">You need to fill in this field</error>', " ... validator returned error for foo");
};
