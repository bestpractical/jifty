use warnings;
use strict;

package Jifty::Request;

use base qw/Jifty::Object Class::Accessor Clone/;
__PACKAGE__->mk_accessors(qw(arguments just_validating path continuation));

use Jifty::JSON;
use YAML;

=head1 NAME

Jifty::Request - Canonical internal representation of an incoming Jifty request

=head1 DESCRIPTION

A user interacts with Jifty by invoking zero or more B<action>s.  
These can be specified in several ways:

=over

=item web form submission

(which contains specially formatted inputs and hidden arguments),

        
=item (eventually) via the Web Services interface 

by sending XML or YAML to a defined URL on the server

=item (eventually) extra parameters in the path part of the URL


=back

This class parses the submission and makes it available as a protocol-independent
B<Jifty::Request> object.

Each Jifty::Request contains several types of information:

=over 4

=item credentials

Generally this includes the current user object, if one exists.  Some access
mechanisms may specify credentials on each HTTP request and some, like the
standard web user interface, may use a "session" mechanism.

(The exact information used here is application-specified.)

(Not yet implemented.)

=item actions

A request may contain one or more actions; these are represented as Jifty::Request::Action
objects. Each action request has a moniker, a set of submitted arguments, and an
implementation class. An action request can either be active, in which case it is a request
for the action to be executed; otherwise, it merely provides default values for an action
in the response with the same moniker.  (Not that we've defined responses yet.)

=item request options

Various options associated with the request; for example, whether it should return
a response and if so what format the response should be in.  Possibly API versioning
falls here too.  Probably "validate-only" too.

JV: I wanna see more about this

=back 

Actions are specified by several things:

=over 4

=item implementation class

The class which implements the object.  This might be an application class (generally the
case for actions) or a framework class (generally the case for view objects).  (Whether
or not the C<I<MyApp>::Action::> part is considered part of the implementation class name
is a little fuzzy now.)

=item moniker

This string has no semantic value for the Jifty code, but your application can parse it.
It must be unique within a request.  Specifically, Jifty will use the moniker to match up
items in a request with items generated in the course of responding to the request (which
often means you want to include things like record IDs in the moniker), and
the WebForm Request Protocol uses the moniker for grouping, but as far as Jifty is concerned
the moniker is just an arbitrary (non-semicolon-containing) string.

=back

=head1 Jifty WebForm Request Protocol

The primary source of Jifty requests through the website are "WebForm Requests".  These are
requests submitted using CGI GET or POST requests to the Jifty project's website.
(Currently, the URL that Jifty WebForms are sent to is more or less irrelevant, but this might
change.)

Much of this is still open to change.

In addition, if any CGI query B<name> is of the form C<foo=bar;baz=quux> (with an
arbitrary value), it is treated as if the query actually contains the arguments that
it appears to; see L<Jifty::MasonInterp> for details.  This is so that submit buttons
can send multiple arguments. 

WebForm Requests specify their information in the following way:

=over 4

=item authorization information

This is fetched from the session object.  There should be a hook in the application code
that should look at the session object and return this stuff.  (Not sure on the details yet.)

=item actions

Active actions and argument defaults are specified in similar ways.  For
each action, the client sends a query argument whose name is C<J:A-I<moniker>>
and whose value is the fully qualified class name of the action's implementation
class.  This is the "action declaration".  The action's arguments are
specified with query arguments of the form C<J:A:F-I<argumentname>-I<moniker>>.

(For now, the behavior when C<J:ACTIONS> contains a moniker that does not
correspond to any action declaration is undefined.)

=item request options

The existence of C<J:VALIDATE> says that the request is only validating arguments.  Perhaps its
value should dictate the response type; for now it's always returning XML.

=back 

=head1 Jifty WebURL Request Protocol

Not yet designed or implemented.

=head1 Jifty XML REST Request Protocol

Not yet designed or implemented.  (Should be able to load some defaults from URL.)

=head1 Jifty YAML REST Request Protocool

Not yet designed or implemented.  (Should be able to load some defaults from URL.)



=head1 METHODS

=head2 new PARAMHASH

Creates a new request object.  For each key in the I<PARAMHASH>, the
method of that name is called, with the I<PARAMHASH>'s value as its
sole argument.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    $self->{'actions'} = {};
    $self->{'state_variables'} = {};
    $self->{'fragments'} = {};
    $self->arguments({});

    my %args = @_;
    for (keys %args) {
        $self->$_($args{$_}) if $self->can($_);
    }

    return $self;
}

=head2 fill

Attempt to fill in the request from any number of various methods --
YAML, JSON, etc.  Falls back to query parameters.

=cut

sub fill {
    my $self = shift;

    # If this is a subrequest, we need to pull from the mason args in
    # order to avoid infinite looping
    $self->from_mason_args
      if Jifty->web->mason->is_subrequest;

    # Grab content type and posted data, if any
    my $ct   = Jifty->web->mason->cgi_request->header_in("Content-Type");
    my $data = Jifty->web->mason->request_args->{POSTDATA};

    # Check it for something appropriate
    if ($data) {
        if ($ct eq "text/x-json") {
            return $self->from_data_structure(Jifty::JSON::jsonToObj($data));
        } elsif ($ct eq "text/x-yaml") {
            return $self->from_data_structure(YAML::Load($data));
        }
    }

    # Fall back on using the mason args
    return $self->from_mason_args;
}

=head2 from_data_structure

=cut

sub from_data_structure {
    my $self = shift;
    my $data = shift;

    # TODO: continuations

    $self->path($data->{path});

    my %actions = %{$data->{actions} || {}};
    for my $a (values %actions) {
        $self->add_action(moniker   => $a->{moniker},
                          class     => $a->{class},
                          # TODO: ORDER
                          arguments => {map {$_ => $a->{fields}{$_}{value}
                                                || $a->{fields}{$_}{fallback}
                                                || $a->{fields}{$_}{doublefallback}}
                                        keys %{$a->{fields} || {}} },
                         );
    }

    my %variables = %{$data->{variables} || {}};
    for my $v (keys %variables) {
        $self->add_state_variable(key => $v, value => $variables{$v});
    }

    my %fragments = %{$data->{fragments} || {}};
    for my $f (values %fragments) {
        $self->add_fragment(name      => $f->{name},
                            path      => $f->{path},
                            arguments => $f->{args},
                            wrapper   => $f->{wrapper} || 0,
                           );
    }

    return $self;
}

=head2 from_mason_args

Calls C<from_webform> with the current mason request's args.

Returns itself.

=cut

sub from_mason_args {
    my $self = shift;

    $self->path( Jifty->web->mason->request_comp->path );

    return $self->from_webform(%{ Jifty->web->mason->request_args });
}


=head2 from_webform %QUERY_ARGS

Parses web form arguments into the Jifty::Request data structure.
Takes in the query arguments, as parsed by Mason (thus, repeated
arguments have already been turned into array refs).  This does
not wipe out preexisting request data; thus, multiple C<from_*>
functions can be called on the same Jifty::Request.

Returns itself.

=cut

sub from_webform {
    my $self = shift;

    my %args = (@_);

    # We pull in the continuations first, because if we have a
    # J:CLONE, we want the cloned values to be fallbacks
    $self->_extract_continuations_from_webform(%args);

    # Pull in all of the arguments
    $self->arguments(\%args);

    # Extract actions and state variables
    $self->_extract_actions_from_webform(%args);
    $self->_extract_state_variables_from_webform(%args);

    $self->just_validating(1) if defined $args{'J:VALIDATE'} and length $args{'J:VALIDATE'};

    return $self;
}

=head2 merge_param KEY => VALUE

Merges a single query parameter into the request.  This may add
actions, change action arguments, or change state variables.

=cut

sub merge_param {
    my $self = shift;

    my ($key, $value) = @_;
    $self->arguments->{$key} = $value;

    my $args = Jifty->web->mason->{'request_args'};
    push @$args, $key => $value;

    if ($key =~ /^J:A-(?:(\d+)-)?(.+)/s) {
        $self->add_action(moniker => $2, class => $value, order => $1, arguments => {}, active => 1);
    } elsif ($key =~ /^J:A:F-(\w+)-(.+)/s and $self->action($2)) {
        $self->action($2)->argument($1 => $value);
    } elsif ($key =~ /^J:V-(.*)/s) {
        $self->add_state_variable(key => $1, value => $value);
    }
}

sub _extract_state_variables_from_webform {
    my $self = shift;
    my %args = (@_);

    foreach my $state_variable ( keys %args ) {
        if(  $state_variable  =~ /^J:V-(.*)$/s) {
            $self->add_state_variable(
                key     => $1,
                value   => $args{$state_variable}
            );
        }
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

sub _extract_actions_from_webform {
    my $self = shift;
    my %args = (@_);

    my $active_actions;
    if (exists $args{'J:ACTIONS'}) {
        $active_actions = {};
        $active_actions->{$_} = 1 for split ';', $args{'J:ACTIONS'};
    } # else $active_actions stays undef

    for my $maybe_action (keys %args) {
        next unless $maybe_action =~ /^J:A-(?:(\d+)-)?(.+)/s;

        my $order   = $1;
        my $moniker = $2;
        my $class = $args{$maybe_action};

        my $arguments = {};
        for my $type (qw/J:A:F:F:F J:A:F:F J:A:F/) {
            for my $key (keys %args) {
                my ($t, $a, $m) = $self->parse_form_field_name($key);
                $arguments->{$a} = $args{$key} if defined $t and $t eq $type and $m eq $moniker;
            }
        }

        $self->add_action(
            moniker => $moniker,
            class => $class,
            order => $order,
            arguments => $arguments,
            active => ($active_actions ? ($active_actions->{$moniker} || 0) : 1)
        );
    } 
}

sub _extract_continuations_from_webform {
    my $self = shift;
    my %args = (@_);

    # Loading a continuation
    foreach my $continuation_id ($args{'J:C'}, $args{'J:CALL'}  ) {
        next unless $continuation_id;
        $self->continuation(Jifty->web->session->get_continuation($continuation_id));
    }

    if ($args{'J:CLONE'} and Jifty->web->session->get_continuations($args{'J:CLONE'})) {
        my %params = %{Jifty->web->session->get_continuations($args{'J:CLONE'})->request->arguments};
        $self->merge_param($_ => $params{$_}) for keys %params;
    }
}

=head2 call_continuation

Calls the L<Jifty::Continuation> associated with this request, if
there is one.

=cut

sub call_continuation {
    my $self = shift;
    my $cont = $self->arguments->{'J:CALL'};
    return unless $cont and Jifty->web->session->get_continuation($cont);
    $self->continuation(Jifty->web->session->get_continuation($cont));
    $self->continuation->call;
}

=head2 path

Returns the path that was requested

=cut

=head2 just_validating

This method returns true if the client has asked us to not actually _run_ any actions.

=cut

=head2 state_variables

Returns an array of all of this request's state variables

=cut

sub state_variables { 
    my $self = shift;
    return values %{$self->{'state_variables'}};
}

=head2 state_variable NAME

Returns the Jifty::Request::StateVariable object for the variable named
C<NAME>, or undef of there is no such variable.

=cut

sub state_variable {
    my $self = shift;
    my $name = shift;
    return $self->{'state_variables'}{$name};
}

=head2 add_state_variable PARMAMS

Adds a state variable to this request's internal representation.

Takes a key and a value. At some distant point in the future, it might also
make sense for it to take a moniker.

=over

=item key

=item value

=back

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

}





=head2 actions

Returns a list of the actions in the request, as L<Jifty::Request::Action> objects.

=cut

sub actions {
    my $self = shift;
    return sort {($a->order || 0) <=> ($b->order || 0)}
      values %{ $self->{'actions'} };
}

=head2 action MONIKER

Returns a L<Jifty::Request::Action> object for the action with the given moniker,
or undef if no such action was sent.

=cut

sub action {
    my $self = shift;
    my $moniker = shift;
    return $self->{'actions'}{$moniker};
} 



=head2 add_action

Required argument: moniker.

Optional arguments: class, active, arguments.

Adds a L<Jifty::Request::Action> with the given moniker to the Request.
If the request already contains an action with that moniker, it merges 
it in, overriding the implementation class, active state, and B<individual>
arguments.

=cut

sub add_action {
    my $self = shift;
    my %args = (
        moniker => undef,
        class => undef,
        order => undef,
        active => 1,
        arguments => undef,
        @_
    );

    my $action = $self->{'actions'}->{ $args{'moniker'} } || Jifty::Request::Action->new;

    for my $k (qw/moniker class order active/) {
        $action->$k($args{$k}) if defined $args{$k};
    } 
    
    if ($args{'arguments'}) {
        for my $k (keys %{ $args{'arguments'} }) {
            $action->argument($k, $args{'arguments'}{$k});
        } 
    }

    $self->{'actions'}{$args{'moniker'}} = $action;

    $self;
} 


sub fragments {
    my $self = shift;

    return values %{$self->{'fragments'}}
}

sub add_fragment {
    my $self = shift;

    my %args = (
                name      => undef,
                path      => undef,
                arguments => undef,
                wrapper   => undef,
                @_
               );

    my $fragment = $self->{'actions'}->{ $args{'name'} } || Jifty::Request::Fragment->new;

    for my $k (qw/name path wrapper/) {
        $fragment->$k($args{$k}) if defined $args{$k};
    } 
    
    if ($args{'arguments'}) {
        for my $k (keys %{ $args{'arguments'} }) {
            $fragment->argument($k, $args{'arguments'}{$k});
        } 
    }

    $self->{'fragments'}{$args{'name'}} = $fragment;

    return $self;
}


sub do_mapping {
    my $self = shift;

    my %args = (
                request  => Jifty->web->request,
                response => Jifty->web->response,
                @_,
               );

    for (keys %{$self->arguments}) {
        my ($key, $value) = Jifty::Request::Mapper->map(destination => $_, source => $self->arguments->{$_}, %args);
        next unless $key ne $_;
        delete $self->arguments->{$_};
        $self->merge_param($key => $value);
    }
}

package Jifty::Request::Action;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors( qw/moniker arguments class order active/);

sub argument {
    my $self = shift;
    my $key  = shift;

    $self->arguments({}) unless $self->arguments;

    $self->arguments->{$key} = shift if @_;
    $self->arguments->{$key};
}


package Jifty::Request::StateVariable;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors (qw/key value/);


package Jifty::Request::Fragment;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors( qw/name path wrapper arguments/ );

sub argument {
    my $self = shift;
    my $key  = shift;

    $self->arguments({}) unless $self->arguments;

    $self->arguments->{$key} = shift if @_;
    $self->arguments->{$key};
}

1;

