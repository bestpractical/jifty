#!/usr/bin/perl

use warnings;
use strict;

=head1 DESCRIPTION

Tests that Jifty->web->(allow|deny)_actions work; this is to
limit what users can do with temporary credentials (LetMes, etc)

=cut

use Jifty::Test tests => 12;

use_ok('Jifty::Web');
can_ok('Jifty::Web', 'setup_session');
can_ok('Jifty::Web', 'session');

my $web = Jifty::Web->new();
$web->setup_session;

ok($web->is_allowed("Foo"), "Tasks default to positive limit");

$web->allow_actions ( qr'.*' );
ok($web->is_allowed("Foo"), "Positive limit doesn't cause negative limit");

$web->deny_actions ( qr'.*' );
ok(!$web->is_allowed("Foo"), "Later negative limit overrides");
 
$web->allow_actions ( qr'.*' );
ok($web->is_allowed("Foo"), "Even later positive limit overrides again");

$web->deny_actions  ( qr'Foo' );
ok(!$web->is_allowed("Foo"), "Regex negative limit");
ok(!$web->is_allowed("FooBar"), "Matches anywhere");
ok(!$web->is_allowed("ILikeFood"), "Matches anywhere");
ok($web->is_allowed("Bar"), "Doesn't impact other positive");

$web->allow_actions  ( 'ILikeFood' );
ok($web->is_allowed("ILikeFood"), "Positive string exact match");

1;
