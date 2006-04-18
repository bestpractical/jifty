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
    return if $File::Find::name =~ /\.pod$/;
    local $/;
    open(FILE, $_) or return;
    my $data = <FILE>;
    close(FILE);
    $used{$1}++ while $data =~ /^\s*use\s+([\w:]+)/gm;
    while ($data =~ m|^\s*use base qw.([\w\s:]+)|gm) {
        $used{$_}++ for split ' ', $1;
    }
}

my %required;
{ 
    local $/;
    ok(open(MAKEFILE,"Makefile.PL"), "Opened Makefile");
    my $data = <MAKEFILE>;
    close(FILE);
    while ($data =~ /^\s*?requires\('([\w:]+)'(?:\s*=>\s*['"]?([\d\.]+)['"]?)?.*?(?:#(.*))?$/gm) {
        $required{$1} = $2;
        if (defined $3 and length $3) {
            $required{$_} = undef for split ' ', $3;
        }
    }
}

for (sort keys %used) {
    my $first_in = Module::CoreList->first_release($_);
    next if defined $first_in and $first_in <= 5.00803;
    next if /^(Jifty|Jifty::DBI|inc|t|TestApp|Application)(::|$)/;
    ok(exists $required{$_}, "$_ in Makefile.PL");
    delete $used{$_};
    delete $required{$_};
}

for (sort keys %required) {
    my $first_in = Module::CoreList->first_release($_, $required{$_});
    fail("Required module $_ is already in core") if defined $first_in and $first_in <= 5.00803;
}

1;

