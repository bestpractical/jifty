use strict;
use warnings;

package Jifty::Plugin::REST::Dispatcher;
use Jifty::Dispatcher -base;

#before '/=/**' => run {
#    authenticate_user();
#    tangent('/login') unless Jifty->web->current_user->id;
#};

before qr{^ (/=/ .*) \. (js|yml|perl|csv) $}x => run {
    $ENV{HTTP_ACCEPT} = $2;
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

sub list {
    print YAML::Syck::Dump(\@_);
    abort(200);
}

sub list_models {
    list(Jifty->class_loader->models);
}

sub list_model_keys {
    die "hey list keys";
}

sub list_model_items {
    die "hey list items";
}

sub show_item {
    die "hey show items";
}

sub replace_item {
    die "hey replace item";
}

sub delete_item {
    die "hey delete item";
}

sub list_actions {
    die "hey list actions";
}

sub list_action_params {
    die "hey action params";
}

sub run_action {
    die "run action";
}

1;
