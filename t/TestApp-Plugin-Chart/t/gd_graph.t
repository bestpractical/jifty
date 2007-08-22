#!/usr/bin/env perl
use strict;
use warnings;

use lib 't/lib';

# XXX FIXME This is here to prevent a segfault on my machine during testing.
#   -- sterling
use Test::More;
eval "use GD; use GD::Graph::pie; 1";
if ($@) {
    plan skip_all => 'GD::Graph is not installed.';
}
else {
    plan tests => 9;
}

use Jifty::SubTest;
use Jifty::Test;
use Jifty::Test::WWW::Mechanize;

use Jifty::Plugin::Chart::Renderer::GD::Graph;

my $chart_plugin = (Jifty->find_plugin('Jifty::Plugin::Chart'))[0];
$chart_plugin->renderer(
    $chart_plugin->init_renderer('Jifty::Plugin::Chart::Renderer::GD::Graph')
);

my $server = Jifty::Test->make_server;
ok($server, 'got a server');

my $url = $server->started_ok;

my $mech = Jifty::Test::WWW::Mechanize->new;

$mech->get_ok($url . '/graphit', 'try getting /graphit');
my $img_match = qr{<img src="(/chart/gd_graph/S\d+)" };
$mech->content_like($img_match, 'has an img tag');
my ($chart_path) = $mech->content =~ $img_match;

$mech->get_ok($url . $chart_path, 'try getting ' . $chart_path);

my $response = $mech->response;
is($response->header('Content-type'), 'image/png', 'content type set to png');

SKIP: {
    eval "use Image::Info qw/ image_info /";
    skip "Image::Info is not installed", 3 if $@;

    my $imgdata = $mech->content;
    my $info = image_info(\$imgdata);

    diag($info->{error}) if $info->{error};

    is($info->{file_ext}, 'png', 'it is a png file');
    is($info->{width}, 400, 'it is 400 pixels wide');
    is($info->{height}, 500, 'it is 500 pixels tall');
};

