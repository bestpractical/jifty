#!/usr/bin/perl

use warnings;
use strict;

=head1 DESCRIPTION

Makes sure that all of the modules that are 'use'd are listed in the
Makefile.PL as dependencies.

=cut

use Test::More qw(no_plan);
use File::Find;
use Module::CoreList;

my %used;
find( \&wanted, qw/ lib bin t /);

sub wanted {
    return unless -f $_;
    return if $File::Find::dir =~ m!/inc(/|$)!;
    local $/;
    open(FILE, $_) or return;
    my $data = <FILE>;
    close(FILE);
    $used{$1}++ while $data =~ /^use\s+([\w:]+)/gm;
    while ($data =~ m|^use base qw/([\w\s:]+)/|gm) {
        $used{$_}++ for split ' ', $1;
    }
}

my %required;
{ 
    local $/;
    ok(open(MAKEFILE,"Makefile.PL"), "Opened Makefile");
    my $data = <MAKEFILE>;
    close(FILE);
    while ($data =~ /^\s*?requires\('([\w:]+)'.*?(?:#(.*))?$/gm) {
        $required{$1}++;
        if (defined $2 and length $2) {
            $required{$_}++ for split ' ', $2;
        }
    }
}

for (sort keys %used) {
    my $first_in = Module::CoreList->first_release($_);
    next if defined $first_in and $first_in <= 5.00803;
    next if /^(Jifty|BTDT|Jifty::DBI|TestApp|inc|t)/;
    ok(delete $required{$_}, "$_ in Makefile.PL");
    delete $used{$_};
}

for (keys %required) {
    my $first_in = Module::CoreList->first_release($_);
    fail("Required module $_ is already in core") if defined $first_in and $first_in <= 5.006;
}

1;

