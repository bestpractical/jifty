#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

This is a template for your own tests. Copy it and modify it.

=cut

use lib 'plugins/REST/lib';

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 6;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::Server');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();


ok(1, "Loaded the test script");


# on GET    '/=/model'       => \&list_models;

$mech->get_ok("$URL/=/model.yml", "Got model list");
my $list = Jifty::YAML::Load($mech->content);
is(scalar @$list, 1, "Got one model");
is($list->[0],'TestApp::Plugin::REST::Model::User');

# on GET    '/=/model/*'     => \&list_model_keys;
$mech->get_ok('/=/model/User');
is($mech->status,'200');
$mech->get_ok('/=/model/user');
is($mech->status,'200');
$mech->get_ok('/=/model/TestApp::Jifty::Plugin::REST::Model::User');
is($mech->status,'200');
$mech->get_ok('/=/model/TestApp.Jifty.Plugin.REST.Model.User');
is($mech->status,'200');
$mech->get_ok('/=/model/testapp.jifty.plugin.rest.model.user');
is($mech->status,'200');
$mech->get_ok('/=/model/Usery');
is($mech->status,'404');


$mech->get_ok('/=/model/User');
my @keys =  @{get_content()};


# on GET    '/=/model/*/*'   => \&list_model_items;
# on GET    '/=/model/*/*/*' => \&show_item;
# on PUT    '/=/model/*/*/*' => \&replace_item;
# on DELETE '/=/model/*/*/*' => \&delete_item;
# on GET    '/=/action'      => \&list_actions;
# on GET    '/=/action/*'    => \&list_action_params;
# on POST   '/=/action/*'    => \&run_action;
# 

sub get_content { return Jifty::YAML::Load($mech->content)}

1;

