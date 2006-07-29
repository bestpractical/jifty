use strict;
use warnings;

package Jifty::Plugin::REST::Dispatcher;
use CGI qw( start_html end_html ul li a dl dt dd );
use Jifty::Dispatcher -base;
use Jifty::YAML ();
use Jifty::JSON ();
use Data::Dumper ();

#before '/=/**' => run {
#    authenticate_user();
#    tangent('/login') unless Jifty->web->current_user->id;
#};

before qr{^ (/=/ .*) \. (js|json|yml|yaml|perl|pl) $}x => run {
    $ENV{HTTP_ACCEPT} = $2;
    dispatch $1;
};

before POST qr{^ (/=/ .*) ! (DELETE|PUT|GET|POST|OPTIONS|HEAD|TRACE|CONNECT) $}x => run {
    $ENV{REQUEST_METHOD} = $2;
    dispatch $1;
};

on GET    '/=/model/*/*/*' => \&show_item;
on GET    '/=/model/*/*'   => \&list_model_items;
on GET    '/=/model/*'     => \&list_model_columns;
on GET    '/=/model/'      => \&list_models;

on PUT    '/=/model/*/*/*' => \&replace_item;
on DELETE '/=/model/*/*/*' => \&delete_item;

on GET    '/=/action/*'    => \&list_action_params;
on GET    '/=/action/'     => \&list_actions;
on POST   '/=/action/*'    => \&run_action;

sub list { outs(\@_) }

sub outs {
    if ($ENV{HTTP_ACCEPT} =~ /ya?ml/i) {
        Jifty->handler->apache->header_out('text/yaml; charset=UTF-8');
        print Jifty::YAML::Dump(@_);
    }
    elsif ($ENV{HTTP_ACCEPT} =~ /json/i) {
        Jifty->handler->apache->header_out('text/json; charset=UTF-8');
        print Jifty::JSON::objToJson( @_, { singlequote => 1 } );
    }
    elsif ($ENV{HTTP_ACCEPT} =~ /j(?:ava)?s|ecmascript/i) {
        Jifty->handler->apache->header_out('application/javascript; charset=UTF-8');
        print 'var $_ = ', Jifty::JSON::objToJson( @_, { singlequote => 1 } );
    }
    elsif ($ENV{HTTP_ACCEPT} =~ /perl/i) {
        Jifty->handler->apache->header_out('application/perl; charset=UTF-8');
        print Data::Dumper::Dumper(@_);
    }
    elsif (ref($_[0]) eq 'ARRAY') {
        print start_html(-encoding => 'UTF-8', -declare_xml => 1, -title => 'models'),
              ul(map {
                    li(a({-href => Jifty::Web->escape_uri($_).'/'}, Jifty::Web->escape($_)))
              } @{$_[0]}),
              end_html()
    }
    else {
        print start_html(-encoding => 'UTF-8', -declare_xml => 1, -title => 'models'),
              dl(map {
                    dt($_),
                    dd($_[0]->{$_}),
              } sort keys %{$_[0]}),
              end_html()
    }
    abort(200);
}

sub list_models {
    list(Jifty->class_loader->models);
}

sub list_model_columns {
    my ($model) = $1;
    list(map { $_->name } $model->new->columns);
}

sub list_model_items {
    # Normalize model name - fun!
    my ($model, $column) = ($1, $2);
    my $col = $model->new->collection_class->new;
    $col->unlimit;
    $col->columns($column);
    $col->order_by(column => $column);

    list(map { $_->__value($column) } @{ $col->items_array_ref || [] });
}

sub show_item {
    my ($model, $column, $key) = ($1, $2, $3);
    my $rec = $model->new;
    $rec->load_by_cols( $column => $key );
    outs($rec->{values});
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
