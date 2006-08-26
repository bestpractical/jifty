#!/usr/bin/env perl -w
use strict;

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

use Jifty::Test tests => 6;

use_ok('Jifty');
can_ok('Jifty', 'handle');

isa_ok(Jifty->handle, "Jifty::DBI::Handle");
isa_ok(Jifty->handle, "Jifty::DBI::Handle::".Jifty->config->framework('Database')->{'Driver'}); 

can_ok(Jifty->handle->dbh, 'ping');
ok(Jifty->handle->dbh->ping);

