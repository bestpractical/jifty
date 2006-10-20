use strict;
use warnings;

package Jifty::Plugin::REST::Dispatcher;
use CGI qw( start_html end_html ul li a dl dt dd );
use Jifty::Dispatcher -base;
use Jifty::YAML ();
use Jifty::JSON ();
use Data::Dumper ();
use XML::Simple;

before qr{^ (/=/ .*) \. (js|json|yml|yaml|perl|xml|pl) $}x => run {
    $ENV{HTTP_ACCEPT} = $2;
    dispatch $1;
};

before POST qr{^ (/=/ .*) ! (DELETE|PUT|GET|POST|OPTIONS|HEAD|TRACE|CONNECT) $}x => run {
    $ENV{REQUEST_METHOD} = $2;
    dispatch $1;
};

on GET    '/=/model/*/*/*/*' => \&show_item_field;
on GET    '/=/model/*/*/*'   => \&show_item;
on GET    '/=/model/*/*'     => \&list_model_items;
on GET    '/=/model/*'       => \&list_model_columns;
on GET    '/=/model'         => \&list_models;

on PUT    '/=/model/*/*/*' => \&replace_item;
on DELETE '/=/model/*/*/*' => \&delete_item;

on GET    '/=/action/*'    => \&list_action_params;
on GET    '/=/action'      => \&list_actions;
on POST   '/=/action/*'    => \&run_action;

sub list {
    my $prefix = shift;
    outs($prefix, \@_)
}

sub outs {
    my $prefix = shift;
    my $accept = ($ENV{HTTP_ACCEPT} || '');
    my $apache = Jifty->handler->apache;
    my $url    = Jifty->web->url(path => join '/', '=', map { 
        Jifty::Web->escape_uri($_)
    } @$prefix);

    if ($accept =~ /ya?ml/i) {
        $apache->header_out('Content-Type' => 'text/x-yaml; charset=UTF-8');
        $apache->send_http_header;
        print Jifty::YAML::Dump(@_);
    }
    elsif ($accept =~ /json/i) {
        $apache->header_out('Content-Type' => 'application/json; charset=UTF-8');
        $apache->send_http_header;
        print Jifty::JSON::objToJson( @_, { singlequote => 1 } );
    }
    elsif ($accept =~ /j(?:ava)?s|ecmascript/i) {
        $apache->header_out('Content-Type' => 'application/javascript; charset=UTF-8');
        $apache->send_http_header;
        print 'var $_ = ', Jifty::JSON::objToJson( @_, { singlequote => 1 } );
    }
    elsif ($accept =~ /perl/i) {
        $apache->header_out('Content-Type' => 'application/x-perl; charset=UTF-8');
        $apache->send_http_header;
        print Data::Dumper::Dumper(@_);
    }
    elsif ($accept =~  qr|^(text/)?xml$|i) {
        $apache->header_out('Content-Type' => 'text/xml; charset=UTF-8');
        $apache->send_http_header;
        print  render_as_xml(@_);

    }
    else {
         
        $apache->header_out('Content-Type' => 'text/html; charset=UTF-8');
        $apache->send_http_header;
        print render_as_html($prefix, $url, @_);
    }

    last_rule;
}

our $xml_config = { SuppressEmpty => '',
                    NoAttr => 1 };

sub render_as_xml {
    my $content = shift;

    if (ref($content) eq 'ARRAY') {
        return XMLout({value => $content}, %$xml_config);
    }
    elsif (ref($content) eq 'HASH') {
        return XMLout($content, %$xml_config);
    } else {
        return XMLout({$content}, %$xml_config)
    }
}


sub render_as_html {
    my $prefix = shift;
    my $url = shift;
    my $content = shift;
    if (ref($content) eq 'ARRAY') {
        return start_html(-encoding => 'UTF-8', -declare_xml => 1, -title => 'models'),
              ul(map {
                li(a({-href => "$url/".Jifty::Web->escape_uri($_)}, Jifty::Web->escape($_)))
              } @{$content}),
              end_html();
    }
    elsif (ref($content) eq 'HASH') {
        return start_html(-encoding => 'UTF-8', -declare_xml => 1, -title => 'models'),
              dl(map {
                  dt(a({-href => "$url/".Jifty::Web->escape_uri($_)}, Jifty::Web->escape($_))),
                  dd(html_dump($content->{$_})),
              } sort keys %{$content}),
              end_html();
    }
    else {
        return start_html(-encoding => 'UTF-8', -declare_xml => 1, -title => 'models'),
              Jifty::Web->escape($content),
              end_html();
    }
}



sub html_dump {
    my $content = shift;
    if (ref($content) eq 'ARRAY') {
        ul(map {
            li(html_dump($_))
        } @{$content});
    }
    elsif (ref($content) eq 'HASH') {
        dl(map {
            dt(Jifty::Web->escape($_)),
            dd(html_dump($content->{$_})),
        } sort keys %{$content}),
    }
    else {
        Jifty::Web->escape($content);
    }
}

sub action { resolve($_[0], 'Jifty::Action', Jifty->api->actions) }
sub model  { resolve($_[0], 'Jifty::Record', Jifty->class_loader->models) }

sub resolve {
    my $name = shift;
    my $base = shift;
    return $name if $name->isa($base);

    $name =~ s/\W+/\\W+/g;

    foreach my $cls (@_) {
        return $cls if $cls =~ /$name$/i;
    }

    abort(404);
}

sub list_models {
    list(['model'], Jifty->class_loader->models);
}

sub list_model_columns {
    my ($model) = model($1);
    outs(['model', $model], { map { $_->name => { %$_ } } sort { $a->sort_order <=> $b->sort_order}  $model->new->columns });
}

sub list_model_items {

    # Normalize model name - fun!
    my ( $model, $column ) = ( model($1), $2 );
    my $col = $model->new->collection_class->new;
    $col->unlimit;
    $col->columns($column);
    $col->order_by( column => $column );

    list( [ 'model', $model, $column ],
        map { $_->$column() } @{ $col->items_array_ref || [] } );
}

sub show_item_field {
    my ( $model, $column, $key, $field ) = ( model($1), $2, $3, $4 );
    my $rec = $model->new;
    $rec->load_by_cols( $column => $key );
    $rec->id          or abort(404);
    $rec->can($field) or abort(404);
    outs( [ 'model', $model, $column, $key, $field ], $rec->$field());
}

sub show_item {
    my ($model, $column, $key) = (model($1), $2, $3);
    my $rec = $model->new;
    $rec->load_by_cols( $column => $key );
    $rec->id or abort(404);
    outs( ['model', $model, $column, $key], { map {$_ => $rec->$_()} map {$_->name} $rec->columns});
}

sub replace_item {
    die "hey replace item";
}

sub delete_item {
    die "hey delete item";
}

sub list_actions {
    list(['action'], Jifty->api->actions);
}

sub list_action_params {
    my ($action) = action($1) or abort(404);
    Jifty::Util->require($action) or abort(404);
    $action = $action->new or abort(404);

    # XXX - Encapsulation?  Someone please think of the encapsulation!
    no warnings 'redefine';
    local *Jifty::Web::out = sub { shift; print @_ };
    local *Jifty::Action::form_field_name = sub { shift; $_[0] };
    local *Jifty::Action::register = sub { 1 };
    local *Jifty::Web::Form::Field::Unrendered::render = \&Jifty::Web::Form::Field::render;

    print start_html(-encoding => 'UTF-8', -declare_xml => 1, -title => ref($action));
    Jifty->web->form->start;
    for my $name ($action->argument_names) {
        print $action->form_field($name);
    }
    Jifty->web->form->submit( label => 'POST' );
    Jifty->web->form->end;
    print end_html;
    last_rule;
}

sub run_action {
    my ($action_name) = action($1) or abort(404);
    Jifty::Util->require($action_name) or abort(404);
    my $action = $action_name->new or abort(404);

    Jifty->api->is_allowed( $action ) or abort(403);

    my $args = Jifty->web->request->arguments;
    delete $args->{''};

    $action->argument_values({ %$args });
    $action->validate;

    local $@;
    eval { $action->run };

    if ($@ or $action->result->failure) {
        abort(500);
    }

    my $rec = $action->{record};
    if ($rec and $rec->isa('Jifty::Record') and $rec->id) {
        my $url    = Jifty->web->url(path => join '/', '=', map {
            Jifty::Web->escape_uri($_)
        } 'model', ref($rec), 'id', $rec->id);
        Jifty->handler->apache->header_out('Location' => $url);
    }
    #outs(undef, [$action->result->message, Jifty->web->response->messages]);
    print start_html(-encoding => 'UTF-8', -declare_xml => 1, -title => 'models'), ul(map { li(html_dump($_)) } $action->result->message, Jifty->web->response->messages), end_html();

    last_rule;
}

1;
