#!/usr/bin/env perl
package TestApp::Regions::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

template '/' => sub {
    div {{ id is 'mason-wrapper' };
        render_region(
            name => 'mason',
            path => '/mason.html',
        );
    };
};

1;

