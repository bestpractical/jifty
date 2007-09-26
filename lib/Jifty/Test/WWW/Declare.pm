#!/usr/bin/env perl
package Jifty::Test::WWW::Declare;
use strict;
use warnings;
use base qw(Exporter);
BEGIN { require Jifty::Test; require Test::WWW::Declare }

our @EXPORT = qw($server $URL);

our $server;
our $URL;

sub import
{
    my $class = shift;

    # examine the plan
    Test::More->import(@_);

    # set up database and other things
    Jifty::Test->setup($class);

    # export the DSL-ey functions
    Test::WWW::Declare->export_to_level(2);

    # export $server, $URL, and whatever else J:T:W:D adds
    __PACKAGE__->export_to_level(1);

    # create a server (which will be automatically exported)
    $server = Jifty::Test->make_server;
    $URL = $server->started_ok;
}

1;

