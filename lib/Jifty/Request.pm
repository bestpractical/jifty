use warnings;
use strict;

package Jifty::Request;

use base qw/Jifty::Object Class::Accessor Clone/;
__PACKAGE__->mk_accessors(qw(just_validating notes_id));

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

=item view helper states

A request may set state variables of view helpers that are created in a response document.
(Not yet implemented as a part of the Request.)

JV: need a bit more details.

=item request options

Various options associated with the request; for example, whether it should return
a response and if so what format the response should be in.  Possibly API versioning
falls here too.  Probably "validate-only" too.

JV: I wanna see more about this

=back 

Actions and view helpers are specified by several things:

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

XXX TODO: alex, this was something you fixed, right?

(Note that under the current implementation there B<needs>
to be a semicolon; a single C<foo=bar> will not trigger this.  We may want to change
this.)

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

=item view helper states

For each helper, the client sends a query argument whose name is C<J:H-I<moniker>>
and whose value is the fully qualified class name of the helper's implementation
class (eg, C<Jifty::View::Helper::Expandable>).  This is the "helper declaration".
The state variables of the helper are specified with query arguments of the
form C<J:H:S-I<statename>-I<moniker>>.

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

=head2 new


=head1 EXAMPLE DATA STRUCTURE

Here, we'll show an example YAML parse of a typical somewhat complex request. before we get going ;)

=cut

sub new {
    my $class = shift;
    bless {
        'actions' => {},
        'helpers' => {},
    }, $class;
}

=head2 from_mason_args

Calls C<from_webform> with the current mason request's args.

Returns itself.

=cut

sub from_mason_args {
    my $self = shift;

    return $self->from_webform(%{ Jifty->mason->request_args });
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


    # XXX TODO: We can do a lot better performancewise with a nice, happy grep.
    $self->_extract_actions_from_webform(%args);
    $self->_extract_helpers_from_webform(%args);
    $self->_extract_state_variables_from_webform(%args);

    $self->notes_id($args{'J:N'}) if ($args{'J:N'});

    $self->just_validating(1) if defined $args{'J:VALIDATE'} and length $args{'J:VALIDATE'};

    return $self;
}
  

sub _extract_state_variables_from_webform {
    my $self = shift;
    my %args = (@_);

    foreach my $state_variable ( keys %args ) {
        if(  $state_variable  =~ /^J:NV-(.*)$/s) {
        $self->add_next_page_state_variable(
            key     => $1,
            value   => $args{$state_variable}
        );
    } 
        elsif(  $state_variable  =~ /^J:V-(.*)$/s) {
        $self->add_state_variable(
            key     => $1,
            value   => $args{$state_variable}
        );

    }
    }
}


sub _extract_actions_from_webform {
    my $self = shift;
    my %args = (@_);

    my $active_actions;
    if (exists $args{'J:ACTIONS'}) {
        $active_actions->{$_} = 1 for split ';', $args{'J:ACTIONS'};
    } # else $active_actions stays undef

    for my $maybe_action (keys %args) {
        next unless $maybe_action =~ /^J:A-(?:(\d+)-)?(.+)/s;

        my $order   = $1;
        my $moniker = $2;
        my $class = $args{$maybe_action};

        my $arguments = {};
        for my $maybe_super_fallback_argument (keys %args) {
            next unless $maybe_super_fallback_argument =~ /^J:A:F:F:F-(\w+)-\Q$moniker/s;
            $arguments->{$1} = $args{$maybe_super_fallback_argument};
        } 
        for my $maybe_fallback_argument (keys %args) {
            next unless $maybe_fallback_argument =~ /^J:A:F:F-(\w+)-\Q$moniker/s;
            $arguments->{$1} = $args{$maybe_fallback_argument};
        } 
        for my $maybe_argument (keys %args) {
            next unless $maybe_argument =~ /^J:A:F-(\w+)-\Q$moniker/s;
            $arguments->{$1} = $args{$maybe_argument};
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

sub _extract_helpers_from_webform {
    my $self = shift;
    my %args = (@_);

    for my $maybe_helper (keys %args) {
        next unless $maybe_helper =~ /^J:H-(.+)/s;

        my $moniker = $1;
        my $class = $args{$maybe_helper};

        my $states = {};
        for my $maybe_state (keys %args) {
            next unless $maybe_state =~ /^J:H:S-(\w+)-\Q$moniker/s;
            $states->{$1} = $args{$maybe_state};
        } 

        $self->add_helper(
            moniker => $moniker,
            class => $class,
            states => $states,
        );
    } 

}

=head2 helpers_as_query_args [MONIKERS]

Returns a hash (suitable to be passed to C<$framework->query_string>
or turned into hidden inputs) of query arguments to represent the
current view helper state.  May be passed an optional set of monikers
to limit the return values to.

=cut

sub helpers_as_query_args {
    my $self = shift;
    my @monikers = @_ || keys %{$self->{'helpers'}};

    my @args;
    for my $helper (grep {defined} map {$self->helper($_)} @monikers) {
        push @args, "J:H-".$helper->moniker, $helper->class;
        for my $statename (keys %{ $helper->states }) {
            push @args, "J:H:S-$statename-".$helper->moniker, $helper->state($statename);
        } 
    } 
    return @args;
} 


=head2 notes_id

Returns the current request's key for the session notes hash. This is used to get at things
like preserved helpers and the results of actions.

=cut

=head just_validating

This method returns true if the client has asked us to not actually _run_ any actions.

=cut


=head2 next_page_state_variables

Returns an array of all of this request's state variables

=cut

sub next_page_state_variables { 
    my $self = shift;
    return values %{$self->{'next_page_state_variables'}};
}

=head2 next_page_state_variable NAME

Returns the Jifty::Request::StateVariable object for the variable named
NAME.

=cut

sub next_page_state_variable {
    my $self = shift;
    my $name = shift;
    return $self->{'next_page_state_variables'}{$name};

}

=head2 add_next_page_state_variable PARMAMS

Adds a state variable to this request's internal representation.

Takes a key and a value. At some distant point in the future, it might also
make sense for it to take a moniker.

=over

=item key

=item value

=back

=cut

sub add_next_page_state_variable {
    my $self = shift;
    my %args = (
                 key => undef,
                 value => undef,
                 @_);

    my $state_var = Jifty::Request::StateVariable->new();
    
    for my $k (qw/key value/) {
        $state_var->$k($args{$k}) if defined $args{$k};
    } 
    $self->{'next_page_state_variables'}{$args{'key'}} = $state_var;

}


=head2 state_variables

Returns an array of all of this request's state variables

=cut

sub state_variables { 
    my $self = shift;
    return values %{$self->{'state_variables'}};
}

=head2 state_variable NAME

Returns the Jifty::Request::StateVariable object for the variable named
NAME.

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
or undef if no such helper was sent.

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

=head2 helpers

Returns a list of the view helpers in the request, as L<Jifty::Request::Helper> objects.

=cut

sub helpers {
    my $self = shift;
    return values %{ $self->{'helpers'} };
}

=head2 helper MONIKER

Returns a L<Jifty::Request::Helper> object for the helper with the given moniker,
or undef if no such helper was sent.

=cut

sub helper {
    my $self = shift;
    my $moniker = shift;
    return $self->{'helpers'}{$moniker};
} 


=head2 add_helper

Required argument: moniker.

Optional arguments: class, states.

Adds a L<Jifty::Request::Helper> with the given moniker to the Request.
If the request already contains a helper with that moniker, it merges 
it in, overriding the implementation class and B<individual> states.

=cut

sub add_helper {
    my $self = shift;
    my %args = (
        moniker => undef,
        class => undef,
        states => undef,
        @_
    );

    my $helper = $self->{'helpers'}->{ $args{'moniker'} } || Jifty::Request::Helper->new;

    for my $k (qw/moniker class/) {
        $helper->$k($args{$k}) if defined $args{$k};
    } 
    
    if ($args{'states'}) {
        for my $k (keys %{ $args{'states'} }) {
            $helper->state($k, $args{'states'}{$k});
        } 
    }

    $self->{'helpers'}{$args{'moniker'}} = $helper;

    $self;
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

package Jifty::Request::Helper;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors( qw/moniker states class/);

sub state {
    my $self = shift;
    my $key  = shift;

    $self->states({}) unless $self->states;

    $self->states->{$key} = shift if @_;
    $self->states->{$key};
}

package Jifty::Request::StateVariable;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors (qw/key value/);




1;

