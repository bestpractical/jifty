#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist;
use Jifty::Test::WWW::Mechanize;

my @tests = (
    {
        url  => "/path_test/foo",
        text => '/path_test/foo - T::D',
    },
    {
        url  => "/path_test/foo/",
        text => '/path_test/foo - T::D',
    },
    {
        url  => "/path_test/foo/index.html",
        text => '/path_test/foo/index.html - Mason',
    },
    {
        url  => "/path_test/bar",
        text => '/path_test/bar/index.html - T::D',
    },
    {
        url  => "/path_test/bar/index.html",
        text => '/path_test/bar/index.html - T::D',
    },
    {
        url  => "/path_test/in_both",
        text => '/path_test/in_both - T::D',
    },
    {
        url  => "/path_test/mason_only",
        text => '/path_test/mason_only - Mason',
    },
    {
        url  => "/path_test/td_only",
        text => '/path_test/td_only - T::D',
    },
);

plan tests => 2 + scalar(@tests) * 2;

my $server = Jifty::Test->make_server;
isa_ok( $server, 'Jifty::TestServer' );
my $URL = $server->started_ok;

my $mech = Jifty::Test::WWW::Mechanize->new;
foreach my $test (@tests) {
    $mech->get_ok( $URL . $test->{url}, "get '$URL: $test->{url}'" );
    $mech->content_contains( $test->{text}, "found content '$test->{text}'" );
}
