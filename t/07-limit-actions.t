#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Tests that Jifty->api->(allow|deny) work; this is to
limit what users can do with temporary credentials (LetMes, etc)

=cut

use Jifty::Test tests => 21;

use_ok('Jifty::API');

my $api = Jifty::API->new();

ok($api->is_allowed("Jifty::Action::Autocomplete"), "Some Jifty actions are allowed");
ok(!$api->is_allowed("Jifty::Action::Record::Update"), "Most are not");
ok($api->is_allowed("Foo"), "Unqualified tasks default to positive limit");
ok($api->is_allowed("JiftyApp::Action::Foo"), "Qualified tasks default to positive limit");

eval { $api->allow ( qr'.*' ); };
like($@, qr/security reasons/, "Can't allow all actions");

$api->allow ( qr'Foo' );
ok($api->is_allowed("Foo"), "Positive limit doesn't cause negative limit");

$api->deny ( qr'Foo' );
ok(!$api->is_allowed("Foo"), "Later negative limit overrides");
 
$api->allow ( qr'Foo' );
ok($api->is_allowed("Foo"), "Even later positive limit overrides again");

$api->deny  ( qr'Foo' );
ok(!$api->is_allowed("Foo"), "Regex negative limit");
ok(!$api->is_allowed("JiftyApp::Action::Foo"), "Regex negative limit, qualified");
ok(!$api->is_allowed("FooBar"), "Matches anywhere");
ok(!$api->is_allowed("ILikeFood"), "Matches anywhere");
ok($api->is_allowed("Bar"), "Doesn't impact other positive");
ok($api->is_allowed("JiftyApp::Action::Bar"), "Doesn't impact other positive, qualified");

$api->allow  ( 'ILikeFood' );
ok($api->is_allowed("ILikeFood"), "Positive string exact match, unqualified on unqualified");
ok($api->is_allowed("JiftyApp::Action::ILikeFood"), "Positive string exact match, unqualified on qualified");
ok(!$api->is_allowed("ILikeFood::More"), "Positive string subclass match, unqualified on unqualified");

$api->allow  ( 'JiftyApp::Action::ILikeFood' );
ok($api->is_allowed("ILikeFood"), "Positive string exact match, qualified on unqualified");
ok($api->is_allowed("JiftyApp::Action::ILikeFood"), "Positive string exact match, qualified on qualified");
ok(!$api->is_allowed("ILikeFood::More"), "Positive string subclass match, qualified on unqualified");

1;
