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

before qr{^ (/=/ .*) \. (js|json|yml|yaml|perl|pl|xml) $}x => run {
    $ENV{HTTP_ACCEPT} = $2;
    dispatch $1;
};

before POST qr{^ (/=/ .*) ! (DELETE|PUT|GET|POST|OPTIONS|HEAD|TRACE|CONNECT) $}x => run {
    $ENV{REQUEST_METHOD} = $2;
    $ENV{REST_REWROTE_METHOD} = 1;
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

on GET    '/=/action/*'         => \&list_action_params;
on GET    '/=/action'           => \&list_actions;
on POST   '/=/action/*'         => \&run_action;

on GET    '/=/help'             => \&show_help;

=head2 show_help

Shows basic help about resources and formats available via this RESTian interface.

=cut

sub show_help {
    my $apache = Jifty->handler->apache;

    $apache->header_out('Content-Type' => 'text/plain; charset=UTF-8');
    $apache->send_http_header;
   
    print qq{
Accessing resources:

on GET    /=/model                                  list models
on GET    /=/model/<model>                          list model columns
on GET    /=/model/<model>/<column>                 list model items
on GET    /=/model/<model>/<column>/<key>           show item
on GET    /=/model/<model>/<column>/<key>/<field>   show item field

on POST   /=/model/<model>                          create item
on PUT    /=/model/<model>/<column>/<key>           update item
on DELETE /=/model/<model>/<column>/<key>           delete item

on GET    /=/action                                 list actions
on GET    /=/action/<action>                        list action params
on POST   /=/action/<action>                        run action


Resources are available in a variety of formats:

    JSON, JS, YAML, XML, Perl, and HTML

and may be requested in such formats by sending an appropriate HTTP Accept: header
or appending one of the extensions to any resource:

    .json, .js, .yaml, .xml, .pl

HTML is output only if the Accept: header or an extension does not request a
specific format.
    };
    last_rule;
}


=head2 stringify LIST

Takes a list of values and forces them into strings.  Right now all it does
is concatenate them to an empty string, but future versions might be more
magical.

=cut

sub stringify {
    # XXX: allow configuration to specify model fields that are to be
    # expanded
    my @r;

    for (@_) {
        if (UNIVERSAL::isa($_, 'Jifty::Record')) {
            push @r, reference_to_data($_);
        }
        elsif (UNIVERSAL::isa($_, 'Jifty::DateTime')) {
            push @r, _datetime_to_data($_);
        }
        elsif (defined $_) {
            push @r, '' . $_; # force stringification
        }
        else {
            push @r, undef;
        }
    }

    return wantarray ? @r : $r[-1];
}

=head2 reference_to_data

provides a saner output format for models than MyApp::Model::Foo=HASH(0x1800568)

=cut

sub reference_to_data {
    my $obj = shift;
    my ($model) = map { s/::/./g; $_ } ref($obj);
    return { jifty_model_reference => 1, id => $obj->id, model => $model };
}

=head2 object_to_data OBJ

Takes an object and converts the known types into simple data structures.

Current known types:

  Jifty::DBI::Collection
  Jifty::DBI::Record
  Jifty::DateTime

=cut

sub object_to_data {
    my $obj = shift;
    
    my %types = (
        'Jifty::DBI::Collection' => \&_collection_to_data,
        'Jifty::DBI::Record'     => \&_record_to_data,
        'Jifty::DateTime'        => \&_datetime_to_data,
    );

    for my $type ( keys %types ) {
        if ( UNIVERSAL::isa( $obj, $type ) ) {
            return $types{$type}->( $obj );
        }
    }

    # As the last resort, return the object itself and expect the $accept-specific
    # renderer to format the object as e.g. YAML or JSON data.
    return $obj;
}

sub _collection_to_data {
    my $records = shift->items_array_ref;
    return [ map { _record_to_data( $_ ) } @$records ];
}

sub _record_to_data {
    my $record = shift;
    # We could use ->as_hash but this method avoids transforming refers_to
    # columns into JDBI objects

    # XXX: maybe just test ->virtual?
    my %data   = map {
                    $_ => (UNIVERSAL::isa( $record->column( $_ )->refers_to,
                                           'Jifty::DBI::Collection' ) ||
                           $record->column($_)->container
                             ? undef
                             : stringify( $record->_value( $_ ) ) )
                 } $record->readable_attributes;
    return \%data;
}

sub _datetime_to_data {
    my $dt = shift;

    # if it looks like just a date, then return just the date portion
    return $dt->ymd
        if lc($dt->time_zone->name) eq 'floating'
        && $dt->hms('') eq '000000';

    # otherwise let stringification take care of it
    return $dt;
}

=head2 recurse_object_to_data REF

Takes a reference, and calls C<object_to_data> on it if that is
meaningful.  If it is an arrayref, or recurses on each element.  If it
is a hashref, recurses on each value.  Returns the new datastructure.

=cut

sub recurse_object_to_data {
    my $o = shift;
    return $o unless ref $o;

    my $updated = object_to_data($o);
    if ($o ne $updated) {
        return $updated;
    } elsif (ref $o eq "ARRAY") {
        my @a = map {recurse_object_to_data($_)} @{$o};
        return \@a;
    } elsif (ref $o eq "HASH") {
        my %h;
        $h{$_} = recurse_object_to_data($o->{$_}) for keys %{$o};
        return \%h;
    } else {
        return $o;
    }
}


=head2 list PREFIX items

Takes a URL prefix and a set of items to render. passes them on.

=cut

sub list {
    my $prefix = shift;
    outs($prefix, \@_)
}



=head2 outs PREFIX DATASTRUCTURE

TAkes a url path prefix and a datastructure.  Depending on what content types the other side of the HTTP connection can accept,
renders the content as yaml, json, javascript, perl, xml or html.

=cut


sub outs {
    my $prefix = shift;
    my $accept = ($ENV{HTTP_ACCEPT} || '');
    my $apache = Jifty->handler->apache;
    my @prefix;
    my $url;

    if($prefix) {
        @prefix = map {s/::/./g; $_} @$prefix;
         $url    = Jifty->web->url(path => join '/', '=',@prefix);
    }



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
	# XXX: temporary hack to fix _() that aren't respected by json dumper
	for (values %{$_[0]}) {
	    $_->{label} = "$_->{label}" if exists $_->{label} && defined ref $_->{label};
	    $_->{hints} = "$_->{hints}" if exists $_->{hints} && defined ref $_->{hints};
	}
        print 'var $_ = ', Jifty::JSON::objToJson( @_, { singlequote => 1 } );
    }
    elsif ($accept =~ qr{^(?:application/x-)?(?:perl|pl)$}i) {
        $apache->header_out('Content-Type' => 'application/x-perl; charset=UTF-8');
        $apache->send_http_header;
        print Data::Dumper::Dumper(@_);
    }
    elsif ($accept =~  qr|^(text/)?xml$|i) {
        $apache->header_out('Content-Type' => 'text/xml; charset=UTF-8');
        $apache->send_http_header;
        print render_as_xml(@_);
    }
    else {
        $apache->header_out('Content-Type' => 'text/html; charset=UTF-8');
        $apache->send_http_header;
        
        # Special case showing particular actions to show an HTML form
        if (    defined $prefix
            and $prefix->[0] eq 'action'
            and scalar @$prefix == 2 )
        {
            show_action_form($1);
        }
        else {
            print render_as_html($prefix, $url, @_);
        }
    }

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
    if (ref($content) eq 'ARRAY') {
        return start_html(-encoding => 'UTF-8', -declare_xml => 1, -title => 'models'),
              ul(map {
                  li($prefix ?
                     a({-href => "$url/".Jifty::Web->escape_uri($_)}, Jifty::Web->escape($_))
                     : Jifty::Web->escape($_) )
              } @{$content}),
              end_html();
    }
    elsif (ref($content) eq 'HASH') {
        return start_html(-encoding => 'UTF-8', -declare_xml => 1, -title => 'models'),
              dl(map {
                  dt($prefix ?
                     a({-href => "$url/".Jifty::Web->escape_uri($_)}, Jifty::Web->escape($_))
                     : Jifty::Web->escape($_)),
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


=head2 html_dump DATASTRUCTURE

Recursively render DATASTRUCTURE as some simple html dls and ols. 

=cut


sub html_dump {
    my $content = shift;
    if (ref($content) eq 'ARRAY') {
        if (keys %$content) {
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

Canonicalizes ACTION into the form preferred by the code. (Cleans up casing, canonicalizing, etc. Returns 404 if it can't work its magic

=cut


sub action {  _resolve($_[0], 'Jifty::Action', Jifty->api->actions) }

=head2 model MODEL

Canonicalizes MODEL into the form preferred by the code. (Cleans up casing, canonicalizing, etc. Returns 404 if it can't work its magic

=cut

sub model  { _resolve($_[0], 'Jifty::Record', Jifty->class_loader->models) }

sub _resolve {
    my $name = shift;
    my $base = shift;
    return $name if $name->isa($base);

    $name =~ s/\W+/\\W+/g;

    foreach my $cls (@_) {
        return $cls if $cls =~ /$name$/i;
    }

    abort(404);
}


=head2 list_models

Sends the user a list of models in this application, with the names transformed from Perlish::Syntax to Everything.Else.Syntax

=cut

sub list_models {
    list(['model'], map { s/::/./g; $_ } Jifty->class_loader->models);
}

our @column_attrs = 
qw( name
    type
    default
    readable writable
    max_length
    mandatory
    distinct
    sort_order
    refers_to
    alias_for_column
    aliased_as
    label hints
    valid_values
);


=head2 list_model_columns

Sends the user a nice list of all columns in a given model class. Exactly which model is shoved into $1 by the dispatcher. This should probably be improved.


=cut

sub list_model_columns {
    my ($model) = model($1);

    my %cols;
    for my $col ( $model->new->columns ) {
        $cols{ $col->name } = { };
        for ( @column_attrs ) {
            my $val = $col->$_();
            $cols{ $col->name }->{ $_ } = $val
                if defined $val and length $val;
        }
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

    # If we don't load the PK, we won't get data
    $col->columns("id", $column);
    $col->order_by( column => $column );

    list( [ 'model', $model, $column ],
        map { stringify($_->$column()) } @{ $col->items_array_ref || [] } );
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
    abort(404) if not scalar grep { $_->name eq $field } $rec->columns;

    outs( [ 'model', $model, $column, $key, $field ], stringify($rec->$field()) );
}

=head2 show_item $model, $column, $key

Loads up a model of type C<$model> which has a column C<$column> with a value C<$key>. Returns all columns for the object

Returns 404 if it doesn't exist.

=cut

sub show_item {
    my ($model, $column, $key) = (model($1), $2, $3);
    my $rec = $model->new;
    $rec->load_by_cols( $column => $key );
    $rec->id or abort(404);
    outs( ['model', $model, $column, $key],  { map {$_ => stringify($rec->$_())} map {$_->name} $rec->columns});
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
        abort(404)         if $prefix eq 'Delete';
        $prefix = 'Create' if $prefix eq 'Update';
    }

    $class =~ s/^[\w\.]+\.//;

    if ( defined $column and defined $key ) {
        Jifty->web->request->argument( $column => $key );
        Jifty->web->request->argument( 'id' => $rec->id )
            if defined $rec->id;
    }
    
    # CGI.pm doesn't handle form encoded data in PUT requests (in fact,
    # it doesn't really handle PUT requests properly at all), so we have
    # to read the request body ourselves and have CGI.pm parse it
    if (    $ENV{'REQUEST_METHOD'} eq 'PUT'
        and (   $ENV{'CONTENT_TYPE'} =~ m|^application/x-www-form-urlencoded$|
              or $ENV{'CONTENT_TYPE'} =~ m|^multipart/form-data$| ) )
    {
        my $cgi    = Jifty->handler->cgi;
        my $length = defined $ENV{'CONTENT_LENGTH'} ? $ENV{'CONTENT_LENGTH'} : 0;
        my $data;

        $cgi->read_from_client( \$data, $length, 0 )
            if $length > 0;

        if ( defined $data ) {
            my @params = $cgi->all_parameters;
            $cgi->parse_params( $data );
            push @params, $cgi->all_parameters;
            
            my %seen;
            my @uniq = map { $seen{$_}++ == 0 ? $_ : () } @params;

            # Add only the newly parsed arguments to the Jifty::Request
            Jifty->web->request->argument( $_ => $cgi->param( $_ ) )
                for @uniq;
        }
    }

    $ENV{REQUEST_METHOD} = 'POST';
    dispatch '/=/action/' . action( $prefix . $class );
}

=head2 list_actions

Returns a list of all actions allowed to the current user. (Canonicalizes Perl::Style to Everything.Else.Style).

=cut

sub list_actions {
    list(['action'], map {s/::/./g; $_} Jifty->api->actions);
}

=head2 list_action_params

Takes a single parameter, $action, supplied by the dispatcher.

Shows the user all possible parameters to the action.

=cut

our @param_attrs = qw(
    name
    type
    default_value
    label
    hints
    mandatory
    ajax_validates
    length
);

sub list_action_params {
    my ($class) = action($1) or abort(404);
    Jifty::Util->require($class) or abort(404);
    my $action = $class->new or abort(404);

    my $arguments = $action->arguments;
    my %args;
    for my $arg ( keys %$arguments ) {
        $args{ $arg } = { };
        for ( @param_attrs ) {
            my $val = $arguments->{ $arg }{ $_ };
            $args{ $arg }->{ $_ } = $val
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
    my ($action) = action(shift) or abort(404);
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
    my ($action_name) = action($1) or abort(404);
    Jifty::Util->require($action_name) or abort(404);
    
    my $args = Jifty->web->request->arguments;
    delete $args->{''};

    my $action = $action_name->new( arguments => $args ) or abort(404);

    Jifty->api->is_allowed( $action_name ) or abort(403);

    $action->validate;

    local $@;
    eval { $action->run };

    if ($@) {
        Jifty->log->warn($@);
        abort(500);
    }

    my $rec = $action->{record};
    if ($action->result->success && $rec and $rec->isa('Jifty::Record') and $rec->id) {
        my $url    = Jifty->web->url(path => join '/', '=', map {
            Jifty::Web->escape_uri($_)
        } 'model', ref($rec), 'id', $rec->id);
        Jifty->handler->apache->header_out('Location' => $url);
    }
    
    my $result = $action->result;

    my $out = {};
    $out->{success} = $result->success;
    $out->{message} = $result->message;
    $out->{error} = $result->error;
    $out->{field_errors} = {$result->field_errors};
    for (keys %{$out->{field_errors}}) {
        delete $out->{field_errors}->{$_} unless $out->{field_errors}->{$_};
    }
    $out->{field_warnings} = {$result->field_warnings};
    for (keys %{$out->{field_warnings}}) {
        delete $out->{field_warnings}->{$_} unless $out->{field_warnings}->{$_};
    }
    $out->{content} = recurse_object_to_data($result->content);
    
    outs(undef, $out);

    last_rule;
}

1;
