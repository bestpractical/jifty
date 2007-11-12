#!/usr/bin/env perl
package TestApp::Plugin::OAuth::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

template '/nuke/the/whales' => page {
    h1 { "Press the shiny red button." }
};

1;

