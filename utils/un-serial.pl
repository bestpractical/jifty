#!/usr/bin/perl

use strict;
use warnings;

for my $file (@ARGV) {
    my $read;
    unless (open($read, "<", $file)) {
        warn "Can't open $file: $!";
        next;
    }
    my $lines = do {undef $/; <$read>};
    close $read;

    my $s = 1;
    while ($lines =~ /\b(S\d{6,}_\d{5,})/) {
        my $replace = $1;
        $lines =~ s/$replace/S$s/g;
        $s++;
    }

    $file .= ".unserial";
    my $write;
    unless (open($write, ">", $file)) {
        warn "Can't open $file for writing: $!";
        next;
    }
    print $write $lines;
    close $write;
}
