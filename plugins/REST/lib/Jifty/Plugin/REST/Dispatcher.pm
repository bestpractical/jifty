use strict;
use warnings;

package Jifty::Plugin::REST;
use Jifty::Dispatcher -base;

#before '/=/**' => run {
#    authenticate_user();
#    tangent('/login') unless Jifty->web->current_user->id;
#};

before qr{^ (/=/ .*) \. (js|yml|perl|csv) $}x => run {
    header(Accept => $2);
    dispatch $1;
};

before POST qr{^ (/=/ .*) ! (DELETE|PUT|GET|POST|OPTIONS|HEAD|TRACE|CONNECT) $}x => run {
    $ENV{REQUEST_METHOD} = $2;
    dispatch $1;
};

on GET    '/=/model'       => \&list_models;
on GET    '/=/model/*'     => \&list_model_keys;
on GET    '/=/model/*/*'   => \&list_model_items;
on GET    '/=/model/*/*/*' => \&show_item;

on PUT    '/=/model/*/*/*' => \&replace_item;
on DELETE '/=/model/*/*/*' => \&delete_item;

on GET    '/=/action'      => \&list_actions;
on GET    '/=/action/*'    => \&list_action_params;
on POST   '/=/action/*'    => \&run_action;

sub list_models {
}

sub list_model_keys {
}

sub list_model_items {
}

sub show_item {
}

sub replace_item {
}

sub delete_item {
}

sub list_actions {
}

sub list_action_params {
}

sub run_action {
}


1;
