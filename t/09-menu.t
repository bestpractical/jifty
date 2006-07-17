#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(no_plan);

use_ok('Jifty');
use_ok('Jifty::Web::Menu');

my $output;
$ENV{REQUEST_URI} = '';
no warnings qw( redefine once );
*Jifty::Web::out = sub { $output .= $_[1] };
*Jifty::Web::request = sub { bless {}, 'FakeRequest' };
*FakeRequest::path = sub { '/' };
*FakeRequest::continuation = sub { undef };
*_ = sub { $_[0] };

my $top = Jifty::Web::Menu->new;
$top->child('Home'  => url => "/",   sort_order => 0);
$top->child('Item1' => url => "/1/", sort_order => 1);
$top->child('Item2' => url => "/2/", sort_order => 2);

$top->render_as_menu;
like($output, qr{ "/" .* Home .* "/1/" .* Item1 .* "/2/" .* Item2 }sx, "menu rendered");
