package Email::Send::Jifty::Test;
require Jifty::Test;
use strict;
use warnings;

=head1 NAME

Email::Send::Jifty::Test - fix namespace

=head1 WHY?

Because L<Email::Send> 1.99_01 requires senders to be in this namespace.

=cut

*is_available = \&Jifty::Test::is_available;
*send = \&Jifty::Test::send;

1;

