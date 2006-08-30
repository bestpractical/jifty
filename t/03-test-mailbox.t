#!/usr/bin/env perl -w

use strict;

use Jifty::Test tests => 2;

Jifty::Test->setup_mailbox;
ok -r Jifty::Test->mailbox or diag $!;

Jifty::Test->teardown_mailbox;
ok !-e Jifty::Test->mailbox or diag $!;
