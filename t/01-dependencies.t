#!/usr/bin/perl

use warnings;
use strict;

=head1 DESCRIPTION

Makes sure that all of the modules that are 'use'd are listed in the
Makefile.PL as dependencies.

=cut

use Test::More qw(no_plan);
use File::Find;

my %used;
find( \&wanted, qw/ lib bin t /);

sub wanted {
    return unless -f $_;
    local $/;
    open(FILE, $_) or return;
    my $data = <FILE>;
    close(FILE);
    $used{$1}++ while $data =~ /^use\s+([\w:]+)/gm;
    while ($data =~ m|^use base qw/([^/]+)/|gm) {
        $used{$_}++ for split ' ', $1;
    }
}

my %required;
{ 
    local $/;
    ok(open(MAKEFILE,"Makefile.PL"), "Opened Makefile");
    my $data = <MAKEFILE>;
    close(FILE);
    while ($data =~ /^requires\('([\w:]+)'.*?(?:#(.*))?$/gm) {
        $required{$1}++;
        if (defined $2 and length $2) {
            $required{$_}++ for split ' ', $2;
        }
    }
}

for (sort keys %used) {
    next if /JFDI|BTDT|Jifty::DBI/ or lc $_ eq $_;
    ok(delete $required{$_}, "$_ in Makefile.PL");
    delete $used{$_};
}

1;

