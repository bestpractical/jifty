use warnings;
use strict;

package Jifty::Plugin::REST::Dispatcher;




use CGI qw( start_html end_html ol ul li a dl dt dd );
use Carp;
use Jifty::Dispatcher -base;
use Jifty::YAML ();
use Jifty::JSON ();
use Data::Dumper ();
use XML::Simple;

before qr{^ (/=/ .*) \. (js|json|joose|yml|yaml|perl|pl|xml|html) $}x => run {
    Jifty->web->request->env->{HTTP_ACCEPT} = $2;
    dispatch $1;
};

before POST qr{^ (/=/ .*) ! (DELETE|PUT|GET|POST|OPTIONS|HEAD|TRACE|CONNECT) $}x => run {
    Jifty->web->request->method($2);
    Jifty->web->request->env->{REST_REWROTE_METHOD} = 1;
    dispatch $1;
};

on GET    '/=/model/*/*/*/*'    => \&show_item_field;
on GET    '/=/model/*/*/*'      => \&show_item;
on GET    '/=/model/*/*'        => \&list_model_items;
on GET    '/=/model/*'          => \&list_model_columns;
on GET    '/=/model'            => \&list_models;

on POST   '/=/model/*'          => \&create_item;
on PUT    '/=/model/*/*/*'      => \&replace_item;
on DELETE '/=/model/*/*/*'      => \&delete_item;

on GET    '/=/search/*/**'      => \&search_items;

on GET    '/=/action/*'         => \&list_action_params;
on GET    '/=/action'           => \&list_actions;
on POST   '/=/action/*'         => \&run_action;

on GET    '/='                  => \&show_help;
on GET    '/=/help'             => \&show_help;
on GET    '/=/help/*'           => \&show_help_specific;

on GET    '/=/version'          => \&show_version;

=head1 NAME

Jifty::Plugin::REST::Dispatcher - Dispatcher for REST plugin

=head2 show_help

Shows basic help about resources and formats available via this RESTian interface.

=cut

sub show_help {
    Jifty->web->response->content_type('text/plain; charset=utf-8');

    Jifty->web->response->body(qq{
Accessing resources:

on GET    /=/model                                   list models
on GET    /=/model/<model>                           list model columns
on GET    /=/model/<model>/<column>                  list model items
on GET    /=/model/<model>/<column>/<key>            show item
on GET    /=/model/<model>/<column>/<key>/<field>    show item field

on POST   /=/model/<model>                           create item
on PUT    /=/model/<model>/<column>/<key>            update item
on DELETE /=/model/<model>/<column>/<key>            delete item

on GET    /=/search/<model>/<c1>/<v1>/<c2>/<v2>/...  search items
on GET    /=/search/<model>/<c1>/<v1>/.../<field>    show matching items' field

on GET    /=/action                                  list actions
on GET    /=/action/<action>                         list action params
on POST   /=/action/<action>                         run action

on GET    /=/help                                    this help page
on GET    /=/help/search                             help for /=/search

on GET    /=/version                                 version information

Resources are available in a variety of formats:

    JSON, JS, YAML, XML, Perl, and HTML

and may be requested in such formats by sending an appropriate HTTP Accept: header
or appending one of the extensions to any resource:

    .json, .js, .yaml, .xml, .pl

HTML is output only if the Accept: header or an extension does not request a
specific format.
});
    last_rule;
}

=head2 show_help_specific

Displays a help page about a specific topic. Will look for a method named
C<show_help_specific_$1>.

=cut

sub show_help_specific {
    my $topic = $1;
    my $method = "show_help_specific_$topic";
    __PACKAGE__->can($method) or abort(404);

    Jifty->web->response->content_type('text/plain; charset=utf-8');
    Jifty->web->response->body(__PACKAGE__->$method);
    last_rule;
}

=head2 show_help_specific_search

Explains /=/search/ a bit more in-depth.

=cut

sub show_help_specific_search {
    return << 'SEARCH';
This interface supports searching arbitrary columns and values. For example, if
you're looking at a Task with due date 1999-12-25 and complete, you can use:

    /=/search/Task/due/1999-12-25/complete/1

If you're looking for just the summaries of these tasks, you can use:

    /=/search/Task/due/1999-12-25/complete/1/summary

Any column in the model is eligible for searching. If you specify multiple
values for the same column, they'll be ORed together. For example, if you're
looking for Tasks with due dates 1999-12-25 OR 2000-12-25, you can use:

    /=/search/Task/due/1999-12-25/due/2000-12-25/


There are also some pseudo-columns. They are prefixed by __ to avoid collisions
with actual column names.

Not:

    .../__not/<column>/<value>

This lets you search for records whose value for the column is NOT equal
to the specified value.

Ordering:

    .../__order_by/<column>
    .../__order_by_asc/<column>
    .../__order_by_desc/<column>

These let you change the output order of the results. Multiple '__order_by's
will be respected.

Pagination:

    .../__page/<number>
    .../__per_page/<number>

These let you control how many results you'll get.
SEARCH
}

=head2 show_version

Displays versions of the various bits of your application.

=cut

sub show_version {
    outs(['version'], {
        Jifty => $Jifty::VERSION,
        REST  => $Jifty::Plugin::REST::VERSION,
    });
}

=head2 list PREFIX items

Takes a URL prefix and a set of items to render. passes them on.

=cut

sub list {
    my $prefix = shift;
    outs($prefix, \@_)
}

=head2 output_format [prefix]

Returns the user's desired output format. Returns a hashref of:

    format: JSON, JS, YAML, XML, Perl, or HTML
    extension: json, js, yml, xml, pl, or html
    content_type: text/x-yaml; charset=UTF-8, etc.
    freezer: \&Jifty::YAML::Dump, etc.


=cut

sub output_format {
    my $prefix = shift;
    my $accept = (Jifty->web->request->env->{HTTP_ACCEPT} || '');

    my (@prefix, $url);
    if ($prefix) {
        @prefix = map {s/::/./g; $_} @$prefix;
        $url    = Jifty->web->url(path => join '/', '=',@prefix);
    }

    if ($accept =~ /ya?ml/i) {
        return {
            format       => 'YAML',
            extension    => 'yml',
            content_type => 'text/x-yaml; charset=UTF-8',
            freezer      => \&Jifty::YAML::Dump,
        };
    }
    elsif ($accept =~ /json/i) {
        return {
            format       => 'JSON',
            extension    => 'json',
            content_type => 'application/json; charset=UTF-8',
            freezer      => \&Jifty::JSON::encode_json,
        };
    }
    elsif ($accept =~ /j(?:ava)?s|ecmascript/i) {
        return {
            format       => 'JS',
            extension    => 'js',
            content_type => 'application/javascript; charset=UTF-8',
            freezer      => sub { 'var $_ = ' . Jifty::JSON::encode_json( @_ ) },
        };
    }
    elsif ($accept =~ /joose/i) {
        my $freezer;

        # Special case showing a particular model to construct a Joose class
        if (    defined $prefix
            and $prefix->[0] eq 'model'
            and scalar @$prefix == 2 )
        {
            $freezer = sub { show_joose_class($prefix->[1]) };
        }
        else {
            $freezer = sub { 'var $_ = ' . Jifty::JSON::encode_json( @_ ) },
        }

        return {
            format       => 'Joose',
            extension    => 'js',
            content_type => 'application/javascript; charset=UTF-8',
            freezer      => $freezer,
        };
    }
    elsif ($accept =~ qr{^(?:application/x-)?(?:perl|pl)$}i) {
        return {
            format       => 'Perl',
            extension    => 'pl',
            content_type => 'application/x-perl; charset=UTF-8',
            freezer      => \&Data::Dumper::Dumper,
        };
    }
    elsif ($accept =~  qr|^(text/)?xml$|i) {
        return {
            format       => 'XML',
            extension    => 'xml',
            content_type => 'text/xml; charset=UTF-8',
            freezer      => \&render_as_xml,
        };
    }
    # if we ever have a non-html fallback case, we should be checking for an
    # $accept of HTML here
    else {
        my $freezer;

        # Special case showing particular actions to show an HTML form
        if (    defined $prefix
            and $prefix->[0] eq 'action'
            and scalar @$prefix == 2 )
        {
            $freezer = sub { show_action_form($prefix->[1]) };
        }
        else {
            $freezer = sub { render_as_html($prefix, $url, @_) };
        }

        return {
            format       => 'HTML',
            extension    => 'html',
            content_type => 'text/html; charset=UTF-8',
            freezer      => $freezer,
        };
    }
}

=head2 outs PREFIX DATASTRUCTURE

TAkes a url path prefix and a datastructure.  Depending on what content types the other side of the HTTP connection can accept,
renders the content as yaml, json, javascript, perl, xml or html.

=cut

sub outs {
    my $prefix = shift;
    my $format = output_format($prefix);
    warn "==> using $format->{format}" if $main::DEBUG;
    Jifty->web->response->content_type($format->{content_type});
    Jifty->web->response->body($format->{freezer}->(@_));

    last_rule;
}

our $xml_config = { SuppressEmpty   => '',
                    NoAttr          => 1,
                    RootName        => 'data' };

=head2 render_as_xml DATASTRUCTURE

Attempts to render DATASTRUCTURE as simple, tag-based XML.

=cut

sub render_as_xml {
    my $content = shift;

    if (ref($content) eq 'ARRAY') {
        return XMLout({value => $content}, %$xml_config);
    }
    elsif (ref($content) eq 'HASH') {
        return XMLout($content, %$xml_config);
    } else {
        return XMLout({value => $content}, %$xml_config)
    }
}


=head2 render_as_html PREFIX URL DATASTRUCTURE

Attempts to render DATASTRUCTURE as simple semantic HTML suitable for humans to look at.

=cut

sub render_as_html {
    my $prefix = shift;
    my $url = shift;
    my $content = shift;

    my $title = _("%1 - REST API", Jifty->config->framework('ApplicationName'));

    if (ref($content) eq 'ARRAY') {
        return start_html(-encoding => 'UTF-8', -declare_xml => 1, -title => $title),
              ul(map {
                ref($_) eq 'HASH' ? render_as_html($url, $prefix,$_) :
                    li(
                    ref($_) eq 'ARRAY' ? render_as_html($url, $prefix,$_) :
                      
                      ($prefix ?
                     a({-href => "$url/".Jifty::Web->escape_uri($_)}, Jifty::Web->escape($_))
                     : Jifty::Web->escape($_) ))
              } @{$content}),
              end_html();
    }
    elsif (ref($content) eq 'HASH') {
        return start_html(-encoding => 'UTF-8', -declare_xml => 1, -title => $title),
              dl(map {
                  dt($prefix ?
                     a({-href => "$url/".Jifty::Web->escape_uri($_)}, Jifty::Web->escape($_))
                     : Jifty::Web->escape($_)),
                  dd(html_dump($content->{$_})),
              } sort keys %{$content}),
              end_html();
    }
    else {
        return start_html(-encoding => 'UTF-8', -declare_xml => 1, -title => $title),
              Jifty::Web->escape($content),
              end_html();
    }
}


=head2 html_dump DATASTRUCTURE

Recursively render DATASTRUCTURE as some simple html dls and ols. 

=cut


sub html_dump {
    my $content = shift;
    if (ref($content) eq 'ARRAY') {
        if (@$content) {
            return ul(map {
                li(html_dump($_))
            } @{$content});
        }
        else {
            return;
        }
    }
    elsif (ref($content) eq 'HASH') {
        if (keys %$content) {
            return dl(map {
                dt(Jifty::Web->escape($_)),
                dd(html_dump($content->{$_})),
            } sort keys %{$content});
        }
        else {
            return;
        }
    
    } elsif (ref($content) && $content->isa('Jifty::Collection')) {
        if ($content->count) {
            return  ol( map { li( html_dump_record($_))  } @{$content->items_array_ref});
        }
        else {
            return;
        }
        
    } elsif (ref($content) && $content->isa('Jifty::Record')) {
          return   html_dump_record($content);
    }
    else {
        Jifty::Web->escape($content);
    }
}

=head2 html_dump_record Jifty::Record

Returns a nice simple HTML definition list of the keys and values of a Jifty::Record object.

=cut


sub html_dump_record {
    my $item = shift;
     my %hash = $item->as_hash;

     return  dl( map {dt($_), dd($hash{$_}) } keys %hash )
}

=head2 action ACTION

Canonicalizes ACTION into the class-name form preferred by Jifty by cleaning up
casing, delimiters, etc. Throws an appropriate HTTP error code if the action is
unavailable.

=cut


sub action {
    _resolve(
        name          => $_[0],
        base          => 'Jifty::Action',
        possibilities => [Jifty->api->visible_actions],
# We do not do this check because we want users to see actions on GET requests,
# like when they're exploring the REST API in their browser.
#        is_allowed    => sub { Jifty->api->is_allowed(shift) },
    );
}

=head2 model MODEL

Canonicalizes MODEL into the class-name form preferred by Jifty by cleaning up
casing, delimiters, etc. Throws an appropriate HTTP error code if the model is
unavailable.

=cut

sub model {
    _resolve(
        name          => $_[0],
        base          => 'Jifty::Record',
        possibilities => [Jifty->class_loader->models],
        is_allowed    => sub { not shift->is_private },
    );
}

sub _resolve {
    my %args = @_;

    # we display actions as "AppName.Action.Foo", so we want to convert those
    # heathen names to be Perl-style
    $args{name} =~ s/\./::/g;

    my $re = qr/(?:^|::)\Q$args{name}\E$/i;

    my $hit;
    foreach my $class (@{ $args{possibilities} }) {
        if ($class =~ $re && $class->isa($args{base})) {
            $hit = $class;
            last;
        }
    }

    abort(404) if !defined($hit);

    abort(403) if $args{is_allowed} && !$args{is_allowed}->($hit);

    return $hit;
}


=head2 list_models

Sends the user a list of models in this application, with the names transformed from Perlish::Syntax to Everything.Else.Syntax

=cut

sub list_models {
    list(['model'], map { s/::/./g; $_ } grep {not $_->is_private} Jifty->class_loader->models);
}

=head2 valid_column

Returns true if the column is a valid column to observe on the model

=cut

our @column_attrs = 
qw( name
    documentation
    type
    default
    readable writable
    display_length
    max_length
    mandatory
    distinct
    sort_order
    refers_to
    by
    alias_for_column
    aliased_as
    label hints
    valid_values
);

sub valid_column {
    my ( $model, $column ) = @_;
    return scalar grep { $_->name eq $column and not $_->virtual and not $_->private } $model->new->columns;
}

=head2 list_model_columns

Sends the user a nice list of all columns in a given model class. Exactly which model is shoved into $1 by the dispatcher. This should probably be improved.


=cut

sub list_model_columns {
    my ($model) = model($1);

    my %cols;
    for my $col ( $model->new->columns ) {
        next if $col->private or $col->virtual;
        $cols{ $col->name } = { };
        for ( @column_attrs ) {
            my $val = $col->$_();
            $cols{ $col->name }->{ $_ } = Scalar::Defer::force($val)
                if defined $val and length $val;
        }
        $cols{ $col->name }{writable} = 0 if exists $cols{$col->name}{writable} and $col->protected;
    }

    outs( [ 'model', $model ], \%cols );
}

=head2 list_model_items MODELCLASS COLUMNNAME

Returns a list of items in MODELCLASS sorted by COLUMNNAME, with only COLUMNAME displayed.  (This should have some limiting thrown in)

=cut


sub list_model_items {
    # Normalize model name - fun!
    my ( $model, $column ) = ( model($1), $2 );
    my $col = $model->new->collection_class->new;
    $col->unlimit;

    # Check that the field is actually a column
    abort(404) unless valid_column($model, $column);

    # If we don't load the PK, we won't get data
    $col->columns("id", $column);
    $col->order_by( column => $column );

    list( [ 'model', $model, $column ],
        map { Jifty::Util->stringify($_->$column()) }
            @{ $col->items_array_ref || [] } );
}


=head2 show_item_field $model, $column, $key, $field

Loads up a model of type C<$model> which has a column C<$column> with a value C<$key>. Returns the value of C<$field> for that object. 
Returns 404 if it doesn't exist.

=cut

sub show_item_field {
    my ( $model, $column, $key, $field ) = ( model($1), $2, $3, $4 );
    my $rec = $model->new;
    $rec->load_by_cols( $column => $key );
    $rec->id          or abort(404);
    $rec->can($field) or abort(404);

    # Check that the field is actually a column (and not some other method)
    abort(404) unless valid_column($model, $field);

    outs( [ 'model', $model, $column, $key, $field ],
          Jifty::Util->stringify($rec->$field()) );
}

=head2 show_item $model, $column, $key

Loads up a model of type C<$model> which has a column C<$column> with a value C<$key>. Returns all columns for the object

Returns 404 if it doesn't exist.

=cut

sub show_item {
    my ($model, $column, $key) = (model($1), $2, $3);
    my $rec = $model->new;

    # Check that the field is actually a column
    abort(404) unless valid_column($model, $column);

    $rec->load_by_cols( $column => $key );
    $rec->id or abort(404);
    $rec->current_user_can('read') or abort(403);

    outs( ['model', $model, $column, $key], $rec->jifty_serialize_format );
}

=head2 search_items $model, [c1, v1, c2, v2, ...] [, $field]

Loads up all models of type C<$model> that match the given columns and values.
If the column and value list has an odd count, then the last item is taken to
be the output column. Otherwise, all items will be returned.

Will throw a 404 if there were no matches, or C<$field> was invalid.

Pseudo-columns:

=over 4

=item __per_page => N

Return the collection as N records per page.

=item __page => N

Return page N of the collection

=item __order_by => C<column>

Order by the given column, ascending.

=item __order_by_desc => C<column>

Order by the given column, descending.

=back

=cut

sub search_items {
    my ($model, $fragment) = (model($1), $2);
    my @pieces = grep {length} split '/', $fragment;
    my $ret = ['search', $model, @pieces];

    # limit to the key => value pairs they gave us
    my $collection = eval { $model->collection_class->new }
        or abort(404);
    $collection->unlimit;

    my $record = $model->new
        or abort(404);

    my $added_order = 0;
    my $per_page;
    my $current_page = 1;

    my %special = (
        __per_page => sub {
            my $N = shift;

            # must be a number
            $N =~ /^\d+$/
                or abort(404);

            $per_page = $N;
        },
        __page => sub {
            my $N = shift;

            # must be a number
            $N =~ /^\d+$/
                or abort(404);

            $current_page = $N;
        },
        __order_by => sub {
            my $col = shift;
            my $order = shift || 'ASC';

            # this will wipe out the default ordering on your model the first
            # time around
            if ($added_order) {
                $collection->add_order_by(
                    column => $col,
                    order  => $order,
                );
            }
            else {
                $added_order = 1;
                $collection->order_by(
                    column => $col,
                    order  => $order,
                );
            }
        },
        __not => sub {
            my $column = shift;
            my $value  = shift @pieces;

            my $canonicalizer = "canonicalize_$column";
            $value = $record->$canonicalizer($value)
                if $record->can($canonicalizer);

            $collection->limit(
                column   => $column,
                value    => $value,
                operator => '!=',
            );
        },
    );

    # this was called __limit before it was generalized
    $special{__limit} = $special{__per_page};

    # /__order_by/name/desc is impossible to distinguish between ordering by
    # 'name', descending, and ordering by 'name', with output column 'desc'.
    # so we use __order_by_desc instead (and __order_by_asc is provided for
    # consistency)
    $special{__order_by_asc}  = $special{__order_by};
    $special{__order_by_desc} = sub { $special{__order_by}->($_[0], 'DESC') };

    while (@pieces > 1) {
        my $column = shift @pieces;
        my $value  = shift @pieces;

        if (exists $special{$column}) {
            $special{$column}->($value);
        }
        else {
            my $canonicalizer = "canonicalize_$column";
            $value = $record->$canonicalizer($value)
                if $record->can($canonicalizer);

            $collection->limit(column => $column, value => $value);
        }
    }

    # if they provided an odd number of pieces, the last is the output column
    my $field;
    if (@pieces) {
        $field = shift @pieces;
    }

    if (defined($per_page) || defined($current_page)) {
        $per_page = 15 unless defined $per_page;
        $current_page = 1 unless defined $current_page;
        $collection->set_page_info(
            current_page => $current_page,
            per_page     => $per_page,
        );
    }

    $collection->count                       or return outs($ret, []);
    $collection->pager->entries_on_this_page or return outs($ret, []);

    # output
    if (defined $field) {
        my $item = $collection->first
            or return outs($ret, []);

        # Check that the field is actually a column
        abort(404) unless valid_column($model, $field);

        my @values;

        # collect the values for $field
        do {
            push @values, $item->$field;
        } while $item = $collection->next;

        outs($ret, \@values);
    }
    else {
        outs($ret, $collection->jifty_serialize_format);
    }
}

=head2 create_item

Implemented by redispatching to a CreateModel action.

=cut

sub create_item { _dispatch_to_action('Create') }

=head2 replace_item

Implemented by redispatching to a CreateModel or UpdateModel action.

=cut

sub replace_item { _dispatch_to_action('Update') }

=head2 delete_item

Implemented by redispatching to a DeleteModel action.

=cut

sub delete_item { _dispatch_to_action('Delete') }

sub _dispatch_to_action {
    my $prefix = shift;
    my ($model, $class, $column, $key) = (model($1), $1, $2, $3);
    my $rec = $model->new;
    $rec->load_by_cols( $column => $key )
        if defined $column and defined $key;

    if ( not $rec->id ) {
        abort(404) if $prefix eq 'Delete' || $prefix eq 'Update';
    }

    $class =~ s/^[\w\.]+\.//;

    # 403 unless the action exists
    my $action = action($prefix . $class);

    if ( defined $column and defined $key ) {
        Jifty->web->request->argument( $column => $key );
        Jifty->web->request->argument( 'id' => $rec->id )
            if defined $rec->id;
    }
    
    Jifty->web->request->method('POST');
    dispatch "/=/action/$action";
}

=head2 list_actions

Returns a list of all actions visible to the current user. (Canonicalizes Perl::Style to Everything.Else.Style).

=cut

sub list_actions {
    list(['action'], map {s/::/./g; $_} Jifty->api->visible_actions);
}

=head2 list_action_params

Takes a single parameter, $action, supplied by the dispatcher.

Shows the user all possible parameters to the action.

=cut

our @param_attrs = qw(
    name
    documentation
    type
    default_value
    label
    hints
    mandatory
    ajax_validates
    length
    valid_values
);

sub list_action_params {
    my ($class) = action($1);
    my $action = $class->new or abort(404);

    my $arguments = $action->arguments;
    my %args;
    for my $arg ( keys %$arguments ) {
        $args{ $arg } = { };
        for ( @param_attrs ) {
            my $val = $arguments->{ $arg }{ $_ };
            $args{ $arg }->{ $_ } = Scalar::Defer::force($val)
                if defined $val and length $val;
        }
    }

    outs( ['action', $class], \%args );
}

=head2 show_action_form $ACTION_CLASS

Takes a single parameter, the class of an action.

Shows the user an HTML form of the action's parameters to run that action.

=cut

sub show_action_form {
    my ($action) = action(shift);
    Jifty::Util->require($action) or abort(404);
    $action = $action->new or abort(404);
    # XXX - Encapsulation?  Someone please think of the encapsulation!
    no warnings 'redefine';
    local *Jifty::Action::form_field_name = sub { shift; $_[0] };
    local *Jifty::Action::register = sub { 1 };
    local *Jifty::Web::Form::Field::Unrendered::render = \&Jifty::Web::Form::Field::render;

    Jifty->web->response->{body} .= start_html(-encoding => 'UTF-8', -declare_xml => 1, -title => ref($action));
    Jifty->web->form->start;
    for my $name ($action->argument_names) {
        Jifty->web->response->{body} .= $action->form_field($name);
    }
    Jifty->web->form->submit( label => 'POST' );
    Jifty->web->form->end;
    Jifty->web->response->{body} .= end_html;
    last_rule;
}

=head2 show_joose_class $MODEL_CLASS

Takes a single parameter, the class of an model.

Generates a Joose class definition of the model's attributes.

=cut

sub show_joose_class {
    my ($model) = model(shift);
    Jifty::Util->require($model) or abort(404);
    (my $class_name = $model) =~ s/.*:://;

    my $cols = {};
    for my $col ( $model->new->columns ) {
        next if $col->private or $col->virtual;

        my $props = {
            jiftyColumn => 1,
        };

        # map Jifty column property names to Joose names
        if ($col->default) {
            $props->{init} = Scalar::Defer::force($col->default);
        }

        if ($col->mandatory) {
            $props->{required} = 1;
        }

        if ($col->readable) {
            if ($col->writable) {
                $props->{is} = 'rw';
            }
            else {
                $props->{is} = 'ro';
            }
        }

        if ($col->name eq 'id') {
            $props->{isa} = 'Joose.Type.Int';
        }
        elsif ($col->is_string) {
            $props->{isa} = 'Joose.Type.Str';
        }
        elsif ($col->is_numeric) {
            $props->{isa} = 'Joose.Type.Num';
        }
        elsif ($col->is_boolean) {
            $props->{isa} = 'Joose.Type.Bool';
        }

        # always coerce because our REST API output is always strings even
        # for int and bool columns
        $props->{coerce} = 1 if $props->{isa};

        $cols->{$col->name} = $props;
    }

    my $properties = {
        isa => 'JiftyModel',
        has => $cols,
    };

    my $class_definition = "Class('$class_name',"
         . Jifty::JSON::encode_json($properties)
         . ");";

    # argh! I don't see any way to let JSON encode barewords. even trying
    # to confuse it with an object that defines a TO_JSON method returning
    # a bareword does not work. and Joose does not let you say isa: 'Super'.
    # better ideas welcome...
    $class_definition =~ s/"isa":"JiftyModel"/"isa":JiftyModel/g;
    $class_definition =~ s/"isa":"Joose\.Type\.(\w+)"/"isa":Joose.Type.$1/g;

    return $class_definition;
}

=head2 run_action 

Expects $1 to be the name of an action we want to run.

Runs the action, I<with the HTTP arguments as its arguments>. That is, it's not looking for Jifty-encoded (J:F) arguments.
If you have an action called "MyApp::Action::Ping" that takes a parameter, C<ip>, this action will look for an HTTP 
argument called C<ip>, (not J:F-myaction-ip).

Returns the action's result.

TODO, doc the format of the result.

On an invalid action name, throws a C<404>.
On a disallowed action mame, throws a C<403>. 
On an internal error, throws a C<500>.

=cut

sub run_action {
    my ($action_name) = action($1);
    Jifty::Util->require($action_name) or abort(404);
    
    my $args = Jifty->web->request->arguments;
    delete $args->{''};

    my $action = $action_name->new( arguments => $args ) or abort(404);

    Jifty->api->is_allowed( $action_name ) or abort(403);

    $action->validate;

    local $@;
    eval { $action->run };

    if ($@) {
        warn $@;
        abort(500);
    }

    my $rec = $action->{record};
    if ($action->result->success && $rec and $rec->isa('Jifty::Record') and $rec->id) {
        my @fragments = ('model', ref($rec), 'id', $rec->id);

        my $path = join '/', '=', map { Jifty::Web->escape_uri($_) } @fragments;

        my $extension = output_format(\@fragments)->{extension};
        $path .= '.' . $extension;

        my $url = Jifty->web->url(path => $path);

        Jifty->web->response->status( 302 );
        Jifty->web->response->header('Location' => $url);
    }

    outs(undef, $action->result->as_hash);

    last_rule;
}

1;
