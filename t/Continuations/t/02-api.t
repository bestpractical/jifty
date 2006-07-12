#!/usr/bin/perl

use warnings;
use strict;

=head1 DESCRIPTION

Continuations tests

=cut

use lib 't/lib';
use Jifty::SubTest;
use lib '../lib';
use Jifty::Test tests => 31;

use_ok('Jifty::Test::WWW::Mechanize');

# Set up server
my $server = Jifty::Test->make_server;
my $URL = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new;

# Check that the first page is as we expect it
$mech->get("$URL/");
$mech->content_like(qr/Get the holy grail/, "Start page has expected content");
$mech->content_unlike(qr/got the grail/, "Start page doesn't have output of run action");

# ..and that the action does what we think it does
$mech->get("$URL/index.html?J:A-grail=Continuations::Action::GetGrail");
$mech->content_like(qr/got the grail/, "Running the action produces the expected result");


#### Create and call
# Create a continuation
ok($mech->find_link( text => "Get help" ), "'Get Help' link exists");
$mech->follow_link_ok( text => "Get help" );

# Redirects to /someplace?J:C=something
like($mech->uri, qr/index-help.html/, "Got to new page");
$mech->content_like(qr/help about the index/i, "Correct content on new page");
ok($mech->continuation, "With a continuation set");
my $first = $mech->continuation->id;
$mech->back;

# Hit same URL again
$mech->follow_link_ok( text => "Get help" );
ok($mech->continuation, "Also sets a continuation");
isnt($first, $mech->continuation->id, "Different continuation this time");

# Call the continuation using J:CALL=id
ok($mech->find_link( text => "Done" ), "Done link exists");
$mech->follow_link_ok( text => "Done" );
like($mech->uri, qr/index.html/, "Back at original page");

# Create continuation from submit with an action
ok($mech->click_button(value => "Help as button"));
$mech->content_unlike(qr/got the grail/i, "Action didn't run");
ok($mech->continuation->request->action("grail"), "Continuation has the action stored");

# Call continuation *to* page with actions
$mech->follow_link_ok( text => "Done" );
like($mech->uri, qr/index.html/, "Back at original page");
$mech->content_like(qr/got the grail/i, "Action ran");


#### Nesting
# Inside one of the existing conts, create a new cont
ok($mech->click_button(value => "Help as button"));
$mech->follow_link_ok( text => "Get help" );
like($mech->uri, qr/help-help.html/, "Got to new page");
$mech->content_like(qr/help about help/i, "Correct content on new page");
ok($mech->continuation, "With a continuation set");
# Calling it should push back to second page
$mech->follow_link_ok( text => "Done" );
like($mech->uri, qr/index-help.html/, "Back at previous page");
# Calling again should push back to original page
$mech->follow_link_ok( text => "Done" );
like($mech->uri, qr/index.html/, "Back at first page");

#### Clone
# Make a new continuation by hand under some existing cont
# Call J:CLONE=it;J:PATH=/somewhere
# Should end up at /somewhere?J:C=new
# With parent the same in both

# Calling clone with an action that doesn't validate should update J:C
# but not push to J:PATH
# But pulls action values into continuation anyways
# XXX: More goes here



1;

