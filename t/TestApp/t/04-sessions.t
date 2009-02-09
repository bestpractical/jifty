#!/usr/bin/env perl 

use warnings;
use strict;

use Jifty::Test::Dist tests => 10;

use_ok('Jifty::Web::Session');

my $s = Jifty::Web::Session->new();

isa_ok($s,'Jifty::Web::Session');

$s->load();
ok($s->loaded);
is($s->get('foo'), undef);
$s->set( foo => 'bar');
is($s->get('foo'), 'bar');

my $id = $s->id;
$s->unload;
ok(!$s->loaded);

$s->load();
ok($s->loaded);
isnt($s->id, $id);
is($s->get('foo'), undef);

$s->load($id);
is($s->get('foo'), 'bar');

1;
