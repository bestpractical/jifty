#!/usr/bin/perl
use warnings;
use strict;

package Jifty::Script::Server;
use base qw/Jifty::Script::Command/;

use Jifty::Everything;
use Jifty::Server;


=head1 NAME

Jifty::Script::Server - A standalone webserver for your Jifty application

=head1 DESCRIPTION

When you're getting started with Jifty, this is the server you want. It's lightweight
    and easy to work with.


=cut


=head1 API

=head2 run

C<run> takes no arguments, but starts up a Jifty server process for you

=cut

sub run {
    Jifty->new();
    Jifty::Server->new()->run;
}
1;
