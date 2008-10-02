#!/usr/bin/perl -w
use strict;
use warnings;
use File::Path 'mkpath';

my $perl = "$^X -Ilib";

system("$perl bin/jifty po");

for (glob("plugins/*")) {
    s{plugins/}{};
    mkpath("plugins/$_/share/po");
    my $name = lc($_);
    system("$perl bin/jifty po --dir plugins/$_ --podir plugins/$_/share/po --template_name jifty_plugin_$name");
}
