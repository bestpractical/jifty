#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Tests that URLs constructed with Jifty->web->url are correct

=cut

BEGIN {
    #### XXX: I know this is foolish but right now Jifty on Win32 fails to 
    #### unlink used test databases and the following tests fail saying
    #### 'error creating a table... table already exists'. So, remove the
    #### remnant first. And we should do it before none of the Jifty is there.

    my $testdb = 'jiftyapptest';
    if (-e $testdb) {
        unlink $testdb or die $!;
    }
}

use Jifty::Test tests => 5;

like(Jifty->web->url, qr{^http://localhost:\d+/$}, 'basic call works');
like(Jifty->web->url(path => 'foo/bar'), qr{^http://localhost:\d+/foo/bar$}, 'path works');
like(Jifty->web->url(path => '/foo/bar'), qr{^http://localhost:\d+/foo/bar$}, 'path with leading slash works');
  
$ENV{HTTP_HOST} = 'example.com';

is(Jifty->web->url, 'http://example.com/', 'setting hostname via env works');
is(Jifty->web->url(path => 'foo/bar'), 'http://example.com/foo/bar', 'hostname via env and path works');
