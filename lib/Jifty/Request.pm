use warnings;
use strict;

package Jifty::Request;

use Any::Moose;
extends 'Jifty::Object';

has 'env' => (is => "ro", isa => "HashRef", default => sub { {} });
has '_top_request' => (is => 'rw');
has 'arguments' => (is => 'rw');
has 'template_arguments' => (is => 'rw');
has 'just_validating' => (is => 'rw');
has 'continuation_id' => (is => 'rw');
has 'future_continuation_id' => (is => 'rw');
has 'continuation_type' => (is => 'rw');
has 'continuation_path' => (is => 'rw');

has 'parameters' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'uploads' => (is => 'rw', isa => 'HashRef');
has 'headers' => (is => 'rw', isa => 'HTTP::Headers', default => sub { HTTP::Headers->new });
has 'uri' => (is => 'rw', isa => 'URI', default => sub { URI->new('http:///') });
has 'cookies' => (is => 'rw', isa => 'HashRef', default => sub { {} } );
has 'scheme' => (is => "rw", isa => "Str", default => sub { 'http' });

has 'request_uri' => (
    is      => "rw",
    isa     => "Str",
);

sub address     { $_[0]->env->{REMOTE_ADDR} }
sub remote_host { $_[0]->env->{REMOTE_HOST} }
sub protocol    { $_[0]->env->{SERVER_PROTOCOL} }
sub method      { $_[0]->env->{REQUEST_METHOD} = $_[1] if @_ > 1; $_[0]->env->{REQUEST_METHOD} }
sub request_method { Carp::carp "request_method is deprecated, use method instead"; goto \&method }
sub port        { $_[0]->env->{SERVER_PORT} }
sub user        { $_[0]->env->{REMOTE_USER} }
sub path_info   { $_[0]->env->{PATH_INFO} }
sub script_name { $_[0]->env->{SCRIPT_NAME} }
sub secure      { $_[0]->scheme eq 'https' }
sub body        { $_[0]->env->{'psgi.input'} }
sub input       { $_[0]->env->{'psgi.input'} }

sub header { shift->headers->header(@_) }
sub path { shift->uri->path(@_) }
sub content_length   { shift->headers->content_length(@_) }
sub content_type     { shift->headers->content_type(@_) }
sub referer          { shift->headers->referer(@_) }
sub user_agent       { shift->headers->user_agent(@_) }

use Jifty::JSON;
use Jifty::YAML;
use Jifty::Web::FileUpload;
use Plack::Util ();

=head1 NAME

Jifty::Request - Canonical internal representation of an incoming Jifty request

=head1 DESCRIPTION

This document discusses the ins and outs of getting data from the web
browser (or any other source) and figuring out what it means.  Most of
the time, you won't need to worry about the details, but they are
provided below if you're curious.

This class parses the submission and makes it available as a
protocol-independent B<Jifty::Request> object.

Each request contains several types of information:

=over 4

=item actions

A request may contain one or more actions; these are represented as
L<Jifty::Request::Action> objects. Each action request has a
L<moniker|Jifty::Manual::Glossary/moniker>, a set of submitted
L<arguments|Jifty::Manual::Glossary/arguments>, and an implementation
class.  By default, all actions that are submitted are run; it is
possible to only mark a subset of the submitted actions as "active",
and only the active actions will be run.  These will eventually become
full-fledge L<Jifty::Action> objects.

=item state variables

State variables are used to pass around bits of information which are
needed more than once but not often enough to be stored in the
session.  Additionally, they are per-browser window, unlike session
information.

=item continuations

Continuations can be called or created during the course of a request,
though each request has at most one "current" continuation.  See
L<Jifty::Continuation>.

=item (optional) fragments

L<Fragments|Jifty::Manual::Glossary/fragments> are standalone bits of
reusable code.  They are most commonly used in the context of AJAX,
where fragments are the building blocks that can be updated
independently.  A request is either for a full page, or for multiple
independent fragments.  See L<Jifty::Web::PageRegion>.

=back

=head1 METHODS

=head2 BUILD PARAMHASH

Creates a new request object.  For each key in the I<PARAMHASH>, the
method of that name is called, with the I<PARAMHASH>'s value as its
sole argument.

=cut

sub BUILD {
    my $self = shift;

    # Copy a bunch of information off of the top Plack request
    if ( Jifty->web->request ) {
        my $env = Jifty->web->request->top_request->env;
        $self->{env}{$_} = $env->{$_} for qw/psgi.version psgi.multithread psgi.multiprocess psgi.errors/;
        # Stub in an empty input filehandle
        $self->{env}{"psgi.input"} = Plack::Util::inline_object( read => sub {0} );
    }

    $self->{'actions'} = {};
    $self->{'state_variables'} = {};
    $self->{'fragments'} = {};
    $self->{env}{'REQUEST_METHOD'} ||= 'GET';

    $self->path("/") unless $self->path;
    $self->arguments({});
    $self->template_arguments({});
}

=head2 clone

Return a copy of the request.

=cut

sub clone {
    my $self = shift;
    
    # "Semi-shallow" clone
    my $ret = bless({map {
        my $val = $self->{$_};
        $_ => (ref($val) eq "HASH" ? { %$val } : ref($val) eq "ARRAY" ? [ @$val ] : $val);
    } keys %$self}, ref($self));

    $ret->uri( $self->uri->clone );
    return $ret;
}

=head2 promote

Attempt to fill in the request from any number of various methods --
YAML, JSON, etc.  Falls back to query parameters.  Takes a
L<Plack::Request> object.

=cut

sub promote {
    my $class = shift;
    my ($req) = @_;

    die Carp::longmess("old calling style") unless ref $req;

    # Import all props from Plack::Request object
    my $self = $class->new( env => $req->env,
                            headers => $req->headers,
                            parameters => $req->parameters->mixed,
                            uploads => $req->uploads->mixed,
                            scheme => $req->scheme,
                            uri => $req->uri,
                            request_uri => $req->request_uri,
                            cookies => $req->cookies,
                            actions => {},
                            state_variables => {},
                            fragments => {},
                            arguments => {},
                            template_arguments => {} );

    # Grab content type and posted data, if any
    my $ct   = $req->content_type;
    my $data = $req->content;

    # Check it for something appropriate
    if ($data) {
        if ($ct =~ m{^text/x-json}) {
            return $self->from_data_structure(eval{Jifty::JSON::decode_json($data)});
        } elsif ($ct =~ m{^text/x-yaml}) {
            return $self->from_data_structure(eval{Jifty::YAML::Load($data)});
        }
    }

    # Fall back on using the straight HTTP arguments
    return $self->from_args;
}

=head2 from_data_structure

Fills in the request from a data structure.  This is called once the
YAML or JSON has been parsed.  See L</SERIALIZATION> for details of
how to construct a proper data structure.

Returns itself.

=cut

sub from_data_structure {
    my $self = shift;
    my $data = shift;

    my $path = $data->{'path'};
    $path ||= $self->path || '/';

    $self->path( Jifty::Util->canonicalize_path( $path, 1 ) );
    $self->just_validating( $data->{validating} ) if $data->{validating};

    if ( ref $data->{continuation} eq "HASH" ) {
        # Back-compat
        $data->{continuation}{current} ||= $data->{continuation}{id};
        delete $data->{continuation}{id} if ($data->{continuation}{type} || "") eq "parent";

        $self->continuation_id( $data->{continuation}{current} );
        $self->future_continuation_id( $data->{continuation}{id} );
        $self->continuation_type( $data->{continuation}{type} );
        $self->continuation_path( $data->{continuation}{create} );
    }

    my %actions = %{ $data->{actions} || {} };
    for my $moniker ( keys %actions ) {
        my $a = $actions{$moniker};
        next unless ref $a eq "HASH";
        my %arguments;
        if ( exists $a->{fields} ) {
            for my $arg ( keys %{ $a->{fields} || {} } ) {
                if ( ref $a->{fields}{$arg} ) {

                    for my $type (qw/fallback value/) {
                        $arguments{$arg} = $a->{fields}{$arg}{$type}
                            if exists $a->{fields}{$arg}{$type};
                    }
                } else {
                    $arguments{$arg} = $a->{fields}{$arg};
                }
            }
        } elsif ( exists $a->{params} ) {
            %arguments = %{$a->{params}};
        }

        $self->add_action(
            moniker => $a->{moniker} || $moniker,
            class   => $a->{class},
            order   => $a->{order},
            active => exists $a->{active} ? $a->{active} : 1,
            arguments => \%arguments,
        );
    }

    my %variables
        = ref $data->{variables} eq "HASH" ? %{ $data->{variables} } : ();
    for my $v ( keys %variables ) {
        $self->add_state_variable( key => $v, value => $variables{$v} );
    }

    my %fragments
        = ref $data->{fragments} eq "HASH" ? %{ $data->{fragments} } : ();
    for my $f ( values %fragments ) {
        next unless ref $f eq "HASH";
        my $current = $self->add_fragment(
            name      => $f->{name},
            path      => $f->{path},
            arguments => $f->{args},
            wrapper   => $f->{wrapper} || 0,
            in_form   => $f->{in_form},
        );
        while ( ref $f->{parent} eq "HASH" and $f = $f->{parent} ) {
            $current = $current->parent(
                Jifty::Request::Fragment->new(
                    {   name      => $f->{name},
                        path      => $f->{path},
                        arguments => $f->{args},
                    }
                )
            );
        }
    }

    return $self;
}

=head2 from_args REQ

Calls C<from_webform> with the L<Plack::Request/parameters>
after splitting C<|>'s in argument names.  See L</argument munging>.

Returns itself.

=cut

sub from_args {
    my $self = shift;

    my %args = %{ $self->parameters };

    # Either CGI.pm or HTML::Mason should really deal with encoding for us.
    for my $k (keys %args) {
        my $val = $args{$k};
        if(ref($val) && ref($val) eq 'ARRAY') {
            $args{$k} = [
                map { Jifty::I18N->promote_encoding( $_, $self->content_type ) }
                  @$val
            ];
        } elsif(!ref($val)) {
            $args{$k} = Jifty::I18N->promote_encoding($val, $self->content_type);
        }
    }

    my $uploads = $self->uploads;
    for my $k ( keys %$uploads ) {
        my $val = $uploads->{$k};
        if ( ref $val eq 'ARRAY' ) {
            $args{$k} =
              [ map { Jifty::Web::FileUpload->new_from_plack($_) } @$val ];
        }
        else {
            $args{$k} = Jifty::Web::FileUpload->new_from_plack($val);
        }
    }
    my @splittable_names = grep /=|\|/, keys %args;
    for my $splittable (@splittable_names) {
        delete $args{$splittable};
        for my $newarg (split /\|/, $splittable) {
            # If your key has a '=', you may just lose
            my ($k, $v) = split /=/, $newarg, 2;
            $args{$k} = $v;
        }
    }
    return $self->from_webform( %args );
}

=head2 from_webform %QUERY_ARGS

Parses web form arguments into the Jifty::Request data structure.
Takes in the query arguments. See L</SERIALIZATION> for details of how
query parameters are parsed.

Returns itself.

=cut

sub from_webform {
    my $self = shift;

    my %args = (@_);

    # Pull in all of the arguments
    $self->arguments(\%args);

    # Extract actions and state variables
    $self->from_data_structure($self->webform_to_data_structure(%args));

    return $self;
}

=head2 argument KEY [=> VALUE]

Merges a single query parameter into the request.  This may add
actions, change action arguments, or change state variables.

=cut

sub argument {
    my $self = shift;

    my $key = shift;
    if (@_) {
        my $value = shift;
        
        $self->arguments->{$key} = $value;

        # Continuation type is often undef, so give it a sane default
        # so we can use eq without warnings
        my $cont_type = $self->continuation_type || "";

        if ($key eq "J:VALIDATE") {
            $self->{validating} = $value;
        } elsif ($key eq "J:C") {
            $self->continuation_id($value);
        } elsif ($key eq "J:CALL" and $cont_type ne "return") {
            # J:CALL doesn't take preference over J:RETURN
            $self->future_continuation_id($value);
            $self->continuation_type("call");
        } elsif ($key eq "J:RETURN") {
            # J:RETURN trumps all
            $self->future_continuation_id($value);
            $self->continuation_type("return");
        } elsif ($key eq "J:PATH") {
            $self->continuation_path($value);
        } elsif ($key =~ /^J:V-(.*)/s) {
            $self->add_state_variable(key => $1, value => $value);
        } elsif ($key =~ /^J:A-(?:(\d+)-)?(.+)/s) {
            $self->add_action(moniker => $2, class => $value, order => $1, arguments => {}, active => 1);
        } else {
            # It's possibly a form field
            my ($t, $a, $m) = $self->parse_form_field_name($key);
            if ($t and $t eq "J:A:F" and $self->action($m)) {
                $self->action($m)->argument($a => $value);
                $self->action($m)->modified(1);
            }
        }
    }

    defined(my $val = $self->arguments->{$key}) or return undef;

    $val;
}

=head2 template_argument KEY [=> VALUE]

Sets an argument for the current template.  Template arguments, unlike
values set via L</argument>, B<cannot> add actions, change action
argument, or change state variables.  They are also not stored in
continuations.

=cut

sub template_argument {
    my $self = shift;

    my $key = shift;
    $self->template_arguments({}) unless $self->template_arguments;
    if (@_) {
        my $value = shift;
        $self->template_arguments->{$key} = $value;
    }
    defined(my $val = $self->template_arguments->{$key}) or return undef;
    $val;
}

=head2 delete KEY

Removes the argument supplied -- this is the opposite of L</argument>,
above.

=cut

sub delete {
    my $self = shift;

    my $key = shift;
    $self->template_arguments({}) unless $self->template_arguments;
    if (exists $self->template_arguments->{$key}) {
        delete $self->template_arguments->{$key};
        return;
    }
    delete $self->arguments->{$key};
    if ($key =~ /^J:A-(?:(\d+)-)?(.+)/s) {
        $self->remove_action($2);
    } elsif ($key =~ /^J:A:F-(\w+)-(.+)/s and $self->action($2)) {
        $self->action($2)->delete($1);
        $self->action($2)->modified(1);
    } elsif ($key =~ /^J:V-(.*)/s) {
        $self->remove_state_variable($1);
    }
}

=head2 parse_form_field_name FIELDNAME

Takes a form field name generated by a Jifty action.
Returns a tuple of

=over 

=item type

A slightly-too-opaque identifier

=item moniker

The moniker for this field's action.

=item argument name

The argument name. 


=back

=cut

sub parse_form_field_name {
    my $self       = shift;
    my $field_name = shift;

    my ( $type, $argument, $moniker );
    if ( $field_name =~ /^(.*?)-(\w+)-(.*)$/ ) {
        $type     = $1;
        $argument = $2;
        $moniker  = $3;
    }

    else {
        return undef;
    }

    return ( $type, $argument, $moniker );
}

=head2 webform_to_data_structure HASHREF

Converts the data from a webform's %args to the datastructure that
L<Jifty::Request> uses internally.

XXX TODO: ALEX: DOC ME

=cut

sub webform_to_data_structure {
    my $self = shift;
    my %args = (@_);


    my $data = {actions => {}, variables => {}};

    # Pass path through
    $data->{path} = $self->path;

    $data->{validating} = $args{'J:VALIDATE'} if defined $args{'J:VALIDATE'} and length $args{'J:VALIDATE'};

    # Continuations
    if ($args{'J:C'}) {
        $data->{continuation}{current} = $args{'J:C'};
    }

    if ($args{'J:CALL'} or $args{'J:RETURN'}) {
        $data->{continuation}{id} = $args{'J:RETURN'} || $args{'J:CALL'};
        $data->{continuation}{type} = "call"   if $args{'J:CALL'};
        $data->{continuation}{type} = "return" if $args{'J:RETURN'};
    }
    if ($args{'J:CREATE'}) {
        $data->{continuation}{create} = $args{'J:PATH'};
    }

    # Are we only setting some actions as active?
    my $active_actions;
    if (exists $args{'J:ACTIONS'}) {
        $active_actions = {};
        $active_actions->{$_} = 1 for split '!', $args{'J:ACTIONS'};
    } # else $active_actions stays undef


    # Mapping from argument types to data structure names;
    my %types = ("J:A:F:F" => "fallback", "J:A:F" => "value");

    # The "sort" here is key; it ensures that action registrations
    # come before action arguments
    for my $key (sort keys %args) {
        my $value = $args{$key};
        if( $key  =~ /^J:V-(.*)/s ) {
            # It's a variable
            $data->{variables}{$1} = $value;
        } elsif ($key =~ /^J:A-(?:(\d+)-)?(.+)/s) {
            # It's an action declatation
            $data->{actions}{$2} = {
                order   => $1,
                moniker => $2,
                class   => $value,
                active  => ($active_actions ? ($active_actions->{$2} || 0) : 1),
            };
        } else {
            # It's possibly a form field
            my ($t, $a, $m) = $self->parse_form_field_name($key);
            next unless $t and $types{$t} and $data->{actions}{$m};
            $data->{actions}{$m}{fields}{$a}{$types{$t}} = $value;
        }
    }

    return $data;
}

=head2 continuation_id [CONTINUATION_ID]

Gets or sets the ID of the current continuation associated with the request.

=cut

=head2 continuation [CONTINUATION]

Returns the current L<Jifty::Continuation> object associated with this
request, if any.

=cut

sub continuation {
    my $self = shift;

    $self->continuation_id(ref $_[0] ? $_[0]->id : $_[0])
      if @_;
 
    return undef unless $self->continuation_id;
    return Jifty->web->session->get_continuation($self->continuation_id);
}

=head2 future_continuation_id

Gets or sets the ID of the continuation that we are about to return or
call into.

=head2 future_continuation

Returns the L<Jifty::Continuation> that we are about to return or call
into, if any.

=cut

sub future_continuation {
    my $self = shift;
    return undef unless defined $self->future_continuation_id;
    return Jifty->web->session->get_continuation($self->future_continuation_id);
}

=head2 save_continuation

Saves the current request and response if we've been asked to.  If we
save the continuation, we redirect to the next page -- the call to
C<save_continuation> never returns.

=cut

sub save_continuation {
    my $self = shift;
    my $path;
    return unless $path = $self->continuation_path;

    # Clear out the create path so we don't ave the "create a
    # continuation" into the continuation!
    $self->continuation_path(undef);

    # Clear out the (locally-set) template arguments, which would
    # bloat the continuation, and can be entirely re-generated.
    $self->template_arguments({});

    my $c = Jifty::Continuation->new(
        request  => $self,
        response => Jifty->web->response,
        parent   => $self->continuation,
    );

    # Set us up with the new continuation
    Jifty->web->_redirect( 
                        $path
                      . ( $path =~ /\?/ ? "&" : "?" ) . "J:C="
                      . $c->id );
}

=head2 call_continuation

Calls the L<Jifty::Continuation> associated with this request, if
there is one.  Returns true if the continuation was called
successfully -- if calling the continuation requires a redirect, this
function will throw an exception to its enclosing dispatcher.

=cut

sub call_continuation {
    my $self = shift;
    return if $self->is_subrequest;
    return unless $self->continuation_type and $self->continuation_type eq "call" and $self->future_continuation;
    $self->log->debug("Calling continuation ".$self->future_continuation->id);
    return $self->future_continuation->call;
}

=head2 return_from_continuation

Returns from the current continuation, if there is one.  If the
request path doesn't match, we call the continuation again, which
should redirect to the right place.  If we have to do this, we return
true, which should be taken as a sign to not process the reqest
further.

=cut

sub return_from_continuation {
    my $self = shift;
    return unless $self->continuation_type and $self->continuation_type eq "return" and $self->future_continuation;
    unless ($self->future_continuation->return_path_matches) {
        # This aborts via Jifty::Dispatcher::_abort -- but we're not
        # in the dispatcher yet, so it would go uncaught.  Catch it
        # here.
        eval {
            $self->future_continuation->call;
        };
        my $err = $@;
        warn $err if $err and $err ne "ABORT";
        return 1;
    }
    $self->log->debug("Returning from continuation ".$self->future_continuation->id);
    $self->future_continuation->return;
    return undef;
}

=head2 path

Returns the path that was requested

=cut

=head2 just_validating

This method returns true if the request was merely for validation.  If
this flag is set, then all active actions are validated, but no
actions are run.

=cut

=head2 state_variables

Returns an array of all of this request's state variables, as
L<Jifty::Request::StateVariable>s.

=cut

sub state_variables { 
    my $self = shift;
    return values %{$self->{'state_variables'}};
}

=head2 state_variable NAME

Returns the L<Jifty::Request::StateVariable> object for the variable
named I<NAME>, or undef of there is no such variable.

=cut

sub state_variable {
    my $self = shift;
    my $name = shift;
    return $self->{'state_variables'}{$name};
}

=head2 add_state_variable PARAMHASH

Adds a state variable to this request's internal representation.
Takes a C<key> and a C<value>; returns the newly-added
L<Jifty::Request::StateVariable>.

=cut

sub add_state_variable {
    my $self = shift;
    my %args = (
                 key => undef,
                 value => undef,
                 @_);

    my $state_var = Jifty::Request::StateVariable->new();
    
    for my $k (qw/key value/) {
        $state_var->$k($args{$k}) if defined $args{$k};
    } 
    $self->{'state_variables'}{$args{'key'}} = $state_var;

    return $state_var;
}

=head2 remove_state_variable KEY

Removes the given state variable.  The opposite of
L</add_state_variable>, above.

=cut

sub remove_state_variable {
    my $self = shift;
    my ($key) = @_;
    delete $self->{'state_variables'}{$key};
}

=head2 clear_state_variables

Remove all the state variables.

=cut

sub clear_state_variables {
    my $self = shift;

    $self->{'state_variables'} = {};
}


=head2 actions

Returns a list of the actions in the request, as
L<Jifty::Request::Action> objects.

=cut

sub actions {
    my $self = shift;
    return sort {($a->order || 0) <=> ($b->order || 0)}
      values %{ $self->{'actions'} };
}

=head2 action MONIKER

Returns a L<Jifty::Request::Action> object for the action with the
given moniker, or undef if no such action was sent.

=cut

sub action {
    my $self = shift;
    my $moniker = shift;
    return $self->{'actions'}{$moniker};
} 

=head2 add_action PARAMHASH

Required argument: C<moniker>.

Optional arguments: C<class>, C<order>, C<active>, C<arguments>.

Adds a L<Jifty::Request::Action> with the given
L<moniker|Jifty::Manual::Glossary/moniker> to the request.  If the
request already contains an action with that moniker, it merges it in,
overriding the implementation class, active state, and B<individual>
arguments.  Returns the newly added L<Jifty::Request::Action>.

See L<Jifty::Action>.

=cut

sub add_action {
    my $self = shift;
    my %args = (
        moniker => undef,
        class => undef,
        order => undef,
        active => 1,
        arguments => undef,
        has_run => 0,
        @_
    );

    my $action = $self->{'actions'}->{ $args{'moniker'} } || Jifty::Request::Action->new;

    for my $k (qw/moniker class order active has_run/) {
        $action->$k($args{$k}) if defined $args{$k};
    } 
    
    if ($args{'arguments'}) {
        for my $k (keys %{ $args{'arguments'} }) {
            $action->argument($k, $args{'arguments'}{$k});
        } 
    }

    $self->{'actions'}{$args{'moniker'}} = $action;

    return $action;
} 


=head2 clear_actions

Removes all actions from this request

=cut

sub clear_actions {
    my $self = shift;
    $self->{'actions'} = {};
}

=head2 remove_action MONIKER

Removes an action with the given moniker.

=cut

sub remove_action {
    my $self = shift;
    my ($moniker) = @_;
    delete $self->{'actions'}{$moniker};
}

=head2 fragments

Returns a list of fragments requested, as L<Jifty::Request::Fragment> objects.

=cut

sub fragments {
    my $self = shift;

    return values %{$self->{'fragments'}}
}

=head2 fragment NAME

Returns the requested fragment with that name

=cut

sub fragment {
    my $self = shift;
    my $name = shift;
    return $self->{'fragments'}{$name};
}

=head2 add_fragment PARAMHASH

Required arguments: C<name>, C<path>

Optional arguments: C<arguments>, C<wrapper>

Adds a L<Jifty::Request::Fragment> with the given name to the request.
If the request already contains a fragment with that name, it merges
it in.  Returns the newly added L<Jifty::Request::Fragment>.

See L<Jifty::PageRegion>.

=cut

sub add_fragment {
    my $self = shift;

    my %args = (
                name      => undef,
                path      => undef,
                arguments => undef,
                wrapper   => undef,
                in_form   => undef,
                @_
               );

    my $fragment = $self->{'fragments'}->{ $args{'name'} } || Jifty::Request::Fragment->new;

    for my $k (qw/name path wrapper in_form/) {
        $fragment->$k($args{$k}) if defined $args{$k};
    } 
    
    if ($args{'arguments'}) {
        for my $k (keys %{ $args{'arguments'} }) {
            $fragment->argument($k, $args{'arguments'}{$k});
        } 
    }

    $self->{'fragments'}{$args{'name'}} = $fragment;

    return $fragment;
}

=head2 do_mapping PARAMHASH

Takes two possible arguments, C<request> and C<response>; they default
to the current L<Jifty::Request> and the current L<Jifty::Response>.
Calls L<Jifty::Request::Mapper/map> on every argument of this request,
pulling arguments and results from the given C<request> and C<response>.

=cut

sub do_mapping {
    my $self = shift;

    my %args = (
                request  => Jifty->web->request,
                response => Jifty->web->response,
                @_,
               );

    for (keys %{$self->arguments}) {
        my ($key, $value) = Jifty::Request::Mapper->map(destination => $_, source => $self->arguments->{$_}, %args);
        next unless $key ne $_ or not defined $value or $value ne $self->argument($_);
        delete $self->arguments->{$_};
        $self->argument($key => $value);
    }
    for ($self->state_variables) {
        my ($key, $value) = Jifty::Request::Mapper->map(destination => $_->key, source => $_->value, %args);
        next unless $key ne $_->key or not defined $value or $value ne $_->value;
        $self->remove_state_variable($_->key);
        $self->add_state_variable(key => $key, value => $value);
    }
}

=head2 is_subrequest

Returns true if this request is a subrequest.

=cut

sub is_subrequest {
    my $self = shift;
    return $self->_top_request ? 1 : undef;
}

=head2 top_request

Returns the top-level request for this request; if this is a
subrequest, this is the user-created request that the handler got
originally.  Otherwise, returns itself;

=cut

sub top_request {
    my $self = shift;
    $self->_top_request(@_) if @_;
    return $self->_top_request || $self;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;


package Jifty::Request::Action;
use Any::Moose;

has 'moniker', is => 'rw';
has 'arguments', is => 'rw';
has 'class', is => 'rw';
has 'order', is => 'rw';
has 'active', is => 'rw';
has 'modified', is => 'rw';
has 'has_run', is => 'rw';

=head2 Jifty::Request::Action

A small package that encapsulates the bits of an action request:

=head3 moniker [NAME]

=head3 argument NAME [VALUE]

=head3 arguments

=head3 class [CLASS]

=head3 order [INTEGER]

=head3 active [BOOLEAN]

=head3 has_run [BOOLEAN]

=cut

sub argument {
    my $self = shift;
    my $key  = shift;

    $self->arguments({}) unless $self->arguments;

    $self->arguments->{$key} = shift if @_;
    $self->arguments->{$key};
}

=head3 delete

=cut

sub delete {
    my $self = shift;
    my $argument = shift;
    delete $self->arguments->{$argument};
}


no Any::Moose;
__PACKAGE__->meta->make_immutable;


package Jifty::Request::StateVariable;
use Any::Moose;

has 'key', is => 'rw';
has 'value', is => 'rw';

no Any::Moose;
__PACKAGE__->meta->make_immutable;

=head2 Jifty::Request::StateVariable

A small package that encapsulates the bits of a state variable:

=head3 key

=head3 value

=cut

package Jifty::Request::Fragment;
use Any::Moose;

has 'name', is => 'rw';
has 'path', is => 'rw';
has 'wrapper', is => 'rw';
has 'in_form', is => 'rw';
has 'arguments', is => 'rw';
has 'parent', is => 'rw';

no Any::Moose;
__PACKAGE__->meta->make_immutable;

=head2 Jifty::Request::Fragment

A small package that encapsulates the bits of a fragment request:

=head3 name [NAME]

=head3 path [PATH]

=head3 wrapper [BOOLEAN]

=head3 in_form [BOOLEAN]

=head3 argument NAME [VALUE]

=head3 arguments

=cut

sub argument {
    my $self = shift;
    my $key  = shift;

    $self->arguments({}) unless $self->arguments;

    $self->arguments->{$key} = shift if @_;
    $self->arguments->{$key};
}

=head3 delete

=cut

sub delete {
    my $self = shift;
    my $argument = shift;
    delete $self->arguments->{$argument};
}

=head1 SERIALIZATION

=head2 CGI Query parameters

The primary source of Jifty requests through the website are CGI query
parameters.  These are requests submitted using CGI GET or POST
requests to your Jifty application.

=head3 argument munging

In addition to standard Mason argument munging, Jifty also takes
arguments with a B<name> of

   bla=bap|beep=bop|foo=bar

and an arbitrary value, and makes them appear as if they were actually
separate arguments.  The purpose is to allow submit buttons to act as
if they'd sent multiple values, without using JavaScript.

=head3 actions

=head4 registration

For each action, the client sends a query argument whose name is
C<J:A-I<moniker>> and whose value is the fully qualified class name of
the action's implementation class.  This is the action "registration."
The registration may also take the form C<J:A-I<order>-I<moniker>>,
which also sets the action's run order.

=head4 arguments

The action's arguments are specified with query arguments of the form
C<J:A:F-I<argumentname>-I<moniker>>.  To cope with checkboxes and the
like (which don't submit anything when left unchecked) we provide a
level of fallback, which is checked if the first doesn't exist:
C<J:A:F:F-I<argumentname>-I<moniker>>.

=head3 state variables

State variables are set via C<J:V-I<name>> being set to the value of
the state parameter.

=head4 continuations

The current continuation set by passing the parameter C<J:C>, which is
set to the id of the continuation.  To create a new continuation, the
parameter C<J:CREATE> is passed.  Calling a continuation is a simple
as passing C<J:CALL> with the id of the continuation to call; this
will redirect to the appropriate url, with L<J:RETURN> set.

=head3 request options

The existence of C<J:VALIDATE> says that the request is only
validating arguments.  C<J:ACTIONS> is set to a semicolon-separated
list of monikers; the actions with those monikers will be marked
active, while all other actions are marked inactive.  In the absence
of C<J:ACTIONS>, all actions are active.

=head2 YAML POST Request Protocol


=head2 JSON POST Request Protocol



=cut

1;

