#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Continuations tests

=cut

use Jifty::Test::Dist tests => 49;

use_ok('Jifty::Test::WWW::Mechanize');

# Create a continuation by hand


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


#### Create
# Create continuation with no return values
$mech->get("$URL/index.html?J:CREATE=1;J:PATH=/index-help.html");
like($mech->uri, qr/index-help.html/, "Got to new page");
$mech->content_like(qr/help about the index/i, "Correct content on new page");
ok($mech->continuation, "With a continuation set");

# Create a continuation using with return values
$mech->get("$URL/index.html?J:CREATE=1;J:M-foo=A`bar;J:PATH=/index-help.html");
like($mech->uri, qr/index-help.html/, "Got to new page");
$mech->content_like(qr/help about the index/i, "Correct content on new page");
ok($mech->continuation, "With a continuation set");
my $first = $mech->continuation->id;

# Hit same URL again
$mech->get("$URL/index.html?J:CREATE=1;J:M-foo=A`bar;J:PATH=/index-help.html");
ok($mech->continuation, "Also sets a continuation");
isnt($first, $mech->continuation->id, "Different continuation this time");

# Create continuation from submit with an action
$mech->get("$URL/index.html?J:CREATE=1;J:M-foo=A`bar;J:PATH=/index-help.html;J:A-grail=GetGrail");
$mech->content_unlike(qr/got the grail/i, "Action didn't run");
ok($mech->continuation->request->action("grail"), "Continuation has the action stored");
my $pending = $mech->continuation->id;

# Create continuation from submit with action that doesn't validate
$mech->get("$URL/index.html?J:CREATE=1;J:M-foo=A`bar;J:PATH=/index-help.html;J:A-cross=CrossBridge");
$mech->content_unlike(qr/crossed the bridge/i, "action didn't run");
ok($mech->continuation->response->result("cross")->failure, "Action's result was failure");


#### Call
# Call the continuation using J:CALL=id
$mech->get("$URL/index-help.html?J:CALL=$first");
like($mech->uri, qr/index.html/, "Back at original page");
unlike($mech->uri, qr/J:CALL=$first/, "With new continuation parameter");
is($mech->status, 200, "Got back happily");
$mech->content_like(qr/Get help/, "Has content after redirect");
my $next = $mech->continuation->id;

# Now with return value
$mech->get("$URL/index-help.html?J:CALL=$first;bar=baz");
like($mech->uri, qr/index.html/, "Back at original page");
unlike($mech->uri, qr/J:CALL=$first/, "With different continuation parameter");
isnt($next, $mech->continuation->id, "Different continuations are different");
$mech->content_like(qr/foo: baz/i, "Return value got to right place");

# Call continuation *to* page with actions
$mech->get("$URL/index-help.html?J:CALL=$pending");
like($mech->uri, qr/index.html/, "Back at original page");
unlike($mech->uri, qr/J:CALL=$pending/, "With new continuation parameter");
$mech->content_like(qr/got the grail/i, "Action ran");

# Call continuation *from* page with actions
# Check that redirect doesn't happen if validation fails
$mech->get("$URL/index-help.html?J:CALL=$first;J:A-cross=CrossBridge");
like($mech->uri, qr/index-help.html/, "Still at same page");
like($mech->uri, qr/J:CALL=$first/, "With same continuation parameter");
$mech->content_unlike(qr/crossed the bridge/i, "action didn't run");
# Check that actions do run before redirect happens if validation succeeds
$mech->get("$URL/index-help.html?J:CALL=$first;J:A-grail=GetGrail");
like($mech->uri, qr/index.html/, "Back at first page");
unlike($mech->uri, qr/J:CALL=$first/, "With new continuation parameter");
$mech->content_like(qr/got the grail/i, "Action ran");


#### Nesting
# Inside one of the existing conts, create a new cont
$mech->get("$URL/index-help.html?J:C=$first;J:CREATE=1;J:M-troz=A`zort;J:PATH=/help-help.html");
like($mech->uri, qr/help-help.html/, "Got to new page");
$mech->content_like(qr/help about help/i, "Correct content on new page");
ok($mech->continuation, "With a continuation set");
isnt($first, $mech->continuation->id, "Is a different continuation from before");
is($first, $mech->continuation->parent, "Has previous continuation as parent");
# Calling it should push back to second page
$mech->get("$URL/help-help.html?J:CALL=".$mech->continuation->id);
like($mech->uri, qr/index-help.html/, "Back at previous page");
$mech->content_like(qr/J:C: (.*)/, "Has continuation set");
$mech->content =~ /J:C: (.*)/;
is($1, $first, "Back at same continuation as before");
# Calling again should push back to original page
$mech->get("$URL/index-help.html?J:CALL=$1");
like($mech->uri, qr/index.html/, "Back at first page");


#### Nested returns
# Inside one of the existing conts, create a new cont with a CALL at the same time
$mech->get("$URL/index-help.html?J:CALL=$first;J:CREATE=1;J:M`troz=A-zort;J:PATH=/help-help.html");
like($mech->uri, qr/help-help.html/, "Got to new page");
$mech->content_like(qr/help about help/i, "Correct content on new page");
ok($mech->continuation, "With a continuation set");
isnt($first, $mech->continuation->id, "Is a different continuation from before");
is($first, $mech->continuation->parent, "Has previous continuation as parent");
# One call should push all the way back to original page
$mech->get("$URL/help-help.html?J:CALL=".$mech->continuation->id);
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

