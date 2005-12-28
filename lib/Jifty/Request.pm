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
L<arguments|Jifty::Manual::Glossary/arguments>, and an implementation class.
By default, all actions that are submitted are run; it is possible to
only mark a subset of the submitted actions as "active", and only the
active actions will be run.  These will eventually become full-fledge
L<Jifty::Action> objects.

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

L<Fragments|Jifty::Manual::Glossary/fragments> are standalone bits of reusable
code.  They are most commonly used in the context of AJAX, where
fragments are the building blocks that can be updated independently.
A request is either for a full page, or for multiple independent
fragments.  See L<Jifty::Web::PageRegion>.

=back

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

Fills in the request from a data structure.  This is called once the
YAML or JSON has been parsed.  See L</SERIALIZATION> for details of
how to construct a proper data structure.

Returns itself.

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

    my $path = $ENV{REQUEST_URI};
    $path =~ s/\?.*//;
    $self->path( $path );

    return $self->from_webform(%{ Jifty->web->mason->request_args });
}


=head2 from_webform %QUERY_ARGS

Parses web form arguments into the Jifty::Request data structure.
Takes in the query arguments, as parsed by Mason (thus, repeated
arguments have already been turned into array refs).  See
L</SERIALIZATION> for details of how query parameters are parsed.

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
Takes a C<key> and a C<value>.

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
L<moniker|Jifty::Manual::Glossary/moniker> to the request.  If the request
already contains an action with that moniker, it merges it in,
overriding the implementation class, active state, and B<individual>
arguments.  See L<Jifty::Action>.

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

=head2 fragments

Returns a list of fragments requested, as L<Jifty::Request::Fragment> objects.

=cut

sub fragments {
    my $self = shift;

    return values %{$self->{'fragments'}}
}

=head2 add_fragment PARAMHASH

Required arguments: C<name>, C<path>

Optional arguments: C<arguments>, C<wrapper>

Adds a L<Jifty::Request::Fragment> with the given name to the request.
If the request already contains a fragment with that name, it merges
it in.  See L<Jifty::PageRegion>.

=cut

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

=head2 do_mapping PARAMHASH

Takes two possible arguments, C<request> and C<response>; they default
to the current L<Jifty::Request> and the current L<Jufty::Response>.
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
        next unless $key ne $_;
        delete $self->arguments->{$_};
        $self->merge_param($key => $value);
    }
}

package Jifty::Request::Action;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors( qw/moniker arguments class order active/);

=head2 Jifty::Request::Action

A small package that encapsulates the bits of an action request:

=head3 moniker [NAME]

=head3 argument NAME [VALUE]

=head3 arguments

=head3 class [CLASS]

=head3 order [INTEGER]

=head3 active [BOOLEAN]

=cut

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

=head2 Jifty::Request::StateVariable

A small package that encapsulates the bits of a state variable:

=head3 key

=head3 value

=cut

package Jifty::Request::Fragment;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors( qw/name path wrapper arguments/ );

=head2 Jifty::Request::Fragment

A small package that encapsulates the bits of a fragment request:

=head3 name [NAME]

=head3 path [PATH]

=head3 wrapper [BOOLEAN]

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

=head1 SERIALIZATION

=head2 CGI Query parameters

The primary source of Jifty requests through the website are CGI query
parameters.  These are requests submitted using CGI GET or POST
requests to your Jifty application.  See L<Jifty::MasonInterp> for
details of the CGI parsing.

=head2 actions

=head3 registration

For each action, the client sends a query argument whose name is
C<J:A-I<moniker>> and whose value is the fully qualified class name of
the action's implementation class.  This is the action "registration."
The registration may also take the form C<J:A-I<order>-I<moniker>>,
which also sets the action's run order.

=head3 arguments

The action's arguments are specified with query arguments of the form
C<J:A:F-I<argumentname>-I<moniker>>.  To cope with checkboxes and the
like (which don't submit anything when left unchecked) we provide two
levels of fallback, which are checked if the first doesn't exist:
C<J:A:F:F-I<argumentname>-I<moniker>> and
C<J:A:F:F:F-I<argumentname>-I<moniker>>.

=head2 state variables

State variables are set via C<J:V-I<name>> being set to the value of
the state parameter.

=head2 continuations

The current continuation set by passing the parameter C<J:C>, which is
set to the id of the continuation.  To create a new continuation, the
parameter C<J:CREATE> is passed.  Calling a continuation is a ssimple
as passing C<J:CALL> with the id of the continuation to call.

=head2 request options

The existence of C<J:VALIDATE> says that the request is only
validating arguments.  C<J:ACTIONS> is set to a semicolon-separated
list of monikers; the actions with those monikers will be marked
active, while all other actions are marked inactive.  In the absence
of C<J:ACTIONS>, all actions are active.

=head1 YAML POST Request Protocool

To be spec'd later

=head1 JSON POST Request Protocool

To be spec'd later

=cut

1;

