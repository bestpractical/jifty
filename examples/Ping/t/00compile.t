#!/usr/bin/perl -w

use Test::More;

use File::Find;

my @modules;
find sub {
    return unless /\.pm$/;
    push @modules, $File::Find::name;
}, "lib";

@modules = map { s[^lib/][];  $_ =~ s[.pm$][];  $_ =~ s[/][::]g; $_ } @modules;

plan tests => scalar @modules;

# Ping::PingServer will not compile without a schema.
system "bin/jifty schema --setup";

for my $module (@modules) {
    require_ok $module;
}
