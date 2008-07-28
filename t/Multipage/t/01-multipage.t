#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Multipage action tests

=cut

use lib 't/lib';
use Jifty::SubTest;
use lib '../lib';
use Jifty::Test tests => 41;

use_ok('Jifty::Test::WWW::Mechanize');

# Set up server
my $server = Jifty::Test->make_server;
my $URL = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new;

# Check that the first page is as we expect it
$mech->get("$URL/");
$mech->content_contains("start on your magical journey", "First page");

# Wrong name
$mech->fill_in_action_ok("multi", name => "bob");
ok($mech->click_button(value => "Next"));
$mech->content_contains("Not alex");
$mech->content_contains("start on your magical journey", "Still first page");

# Right content, gets to page two, contains first page content
$mech->fill_in_action_ok("multi", name => "alex");
ok($mech->click_button(value => "Next"));
$mech->content_contains("Step two");
$mech->content_contains("alex");

# Cancel gets us back
ok($mech->click_button(value => "Cancel"));
$mech->content_contains("start on your magical journey");
$mech->content_lacks("alex");
$mech->back;

# Invalid email address leaves us on page two, remembers state
$mech->fill_in_action_ok("multi", email => "foo");
ok($mech->click_button(value => "Next"));
$mech->content_contains("Not an email address");
$mech->content_contains("Step two", "Still second page");
$mech->content_contains("alex", "Still remembers name");

# Cancel still gets us back
ok($mech->click_button(value => "Cancel"));
$mech->content_contains("start on your magical journey");
$mech->content_lacks("alex");
$mech->back;

# On to page three
$mech->fill_in_action_ok("multi", email => 'foo@bar');
ok($mech->click_button(value => "Next"));
$mech->content_contains("Step three", "Third page");
$mech->content_contains("alex", "Remembers name");
$mech->content_contains('foo@bar', "Remembers email");

# Wrong content on page three leaves us there
$mech->fill_in_action_ok("multi", age => "1");
ok($mech->click_button(value => "Finish"));
$mech->content_contains("Too young");
$mech->content_contains("Step three", "Still third page");
$mech->content_contains("alex", "Still remembers name");
$mech->content_contains('foo@bar', "Still remembers email");

# Cancel still gets us back
ok($mech->click_button(value => "Cancel"));
$mech->content_contains("start on your magical journey");
$mech->content_lacks("alex");
$mech->content_lacks('foo@bar');
$mech->back;

# Right content finishes it off, returning to startpoint
$mech->fill_in_action_ok("multi", age => "25");
ok($mech->click_button(value => "Finish"));
$mech->content_contains(q|All done, 'alex', 'foo@bar', '25'!|, "Completed");
$mech->content_contains('All done!', "Went to final page");
