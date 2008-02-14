#!/usr/bin/env perl
package TestApp::Plugin::OAuth::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

template '/nuke/the/whales' => page {
    h1 { "Press the shiny red button." }
    h2 { "You are human #" . Jifty->web->current_user->id . "." }
};

1;

