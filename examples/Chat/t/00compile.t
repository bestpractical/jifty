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

for my $module (@modules) {
    require_ok $module;
}
