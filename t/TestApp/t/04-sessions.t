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

use Jifty::Test tests => 11;

use_ok('Jifty');
Jifty->new();

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
