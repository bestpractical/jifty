use warnings;
use strict;

package Jifty::Web::Form::Clickable;
use Class::Trigger;
use Scalar::Util qw/blessed/;

=head1 NAME

Jifty::Web::Form::Clickable - Some item that can be clicked on --
either a button or a link.

=head1 DESCRIPTION

=cut

use base 'Jifty::Web::Form::Element';

=head1 METHODS

=head2 accessors

Clickable adds C<url>, C<escape_label>, C<continuation>, C<call>,
C<returns>, C<submit>, and C<preserve_state> to the list of accessors
and mutators, in addition to those offered by
L<Jifty::Web::Form::Element/accessors>.

=cut

sub accessors {
    shift->SUPER::accessors,
        qw(url escape_label tooltip continuation call returns submit target preserve_state render_as_button render_as_link);
}
__PACKAGE__->mk_accessors(
    qw(url escape_label tooltip continuation call returns submit target preserve_state render_as_button render_as_link)
);

=head2 new PARAMHASH

Creates a new L<Jifty::Web::Form::Clickable> object.  Depending on the
requirements, it may render as a link or as a button.  Possible
parameters in the I<PARAMHASH> are:

=over 4

=item url

Sets the page that the user will end up on after they click the
button.  Defaults to the current page.

=item label

The text on the clickable object.

=item tooltip

Additional information about the link target.

=item escape_label

If set to true, HTML escapes the content of the label and tooltip before
displaying them.  This is only relevant for objects that are rendered as
HTML links.  The default is true.

=item continuation

The current continuation for the link.  Defaults to the current
continuation now, if there is one.  This may be either a
L<Jifty::Continuation> object, or the C<id> of such.

=item call

The continuation to call when the link is clicked.  This will happen
after actions have run, if any.  Like C<continuation>, this may be a
L<Jifty::Continuation> object or the C<id> of such.

=item returns

Passing this parameter implies the creation of a continuation when the
link is clicked.  It takes an anonymous hash of return location to
where the return value is pulled from -- that is, the same structure
the C<parameters> method takes.

See L<Jifty::Request::Mapper/query_parameters> for details.

=item submit

A list of actions to run when the object is clicked.  This may be an
array refrence or a single element; each element may either be a
moniker or, a L<Jifty::Action> or a hashref with the keys 'action' and 'arguments'. 
An undefined value submits B<all> actions in the form, an empty list 
reference (the default) submits none.

In the most complex case, you have something like this:

    submit => [
                  {   action    => $my_action,
                      arguments => {
                          name => 'Default McName',
                          age  => '23'
                      },
                  },
                  $my_other_action,
                  'some-other-action-moniker'
              ]

If you specify arguments in the submit block for a button, they will override 
any values from form fields submitted by the user.


=item preserve_state

A boolean; whether state variables are preserved across the link.
Defaults to true if there are any AJAX actions on the link, false
otherwise.

=item parameters

A hash reference of query parameters that go on the link or button.
These will end up being submitted exactly like normal query
parameters.

=item as_button

By default, Jifty will attempt to make the clickable into a link
rather than a button, if there are no actions to run on submit.
Providing a true value for C<as_button> forces L<generate> to produce
a L<Jifty::Web::Form::Clickable::InlineButton> instead of a
L<Jifty::Web::Form::Link>.

=item as_link

Attempt to rework a button into displaying as a link -- note that this
only works in javascript browsers.  Supplying B<both> C<as_button> and
C<as_link> will work, and not as perverse as it might sound at first
-- it allows you to make any simple GET request into a POST request,
while still appearing as a link (a GET request).

=item target

For things that start off as links, give them an html C<target> attribute.

=cut

=item Anything from L<Jifty::Web::Form::Element>

Note that this includes the C<onclick> parameter, which allows
you to attach javascript to your Clickable object, but be careful
that your Javascript looks like C<return someFunction();>, or you may
get an unexpected error from your browser.

=back

=cut

sub new {
    my $class = shift;
    my $root = Jifty->web->request->path;

    my %args = (
        parameters => {},
        @_,
    );

    $class->call_trigger( 'before_new', \%args );

    $args{render_as_button} = delete $args{as_button};
    $args{render_as_link}   = delete $args{as_link};

    my $self = $class->SUPER::new(
        {   class            => '',
            label            => 'Click me!',
            url              => $root,
            escape_label     => 1,
            tooltip          => '',
            continuation     => Jifty->web->request->continuation,
            submit           => [],
            preserve_state   => 0,
            parameters       => {},
            render_as_button => 0,
            render_as_link   => 0,
            %args,
        },
    );

    for (qw/continuation call/) {
        $self->{$_} = $self->{$_}->id if $self->{$_} and ref $self->{$_};
    }

    if ( $self->{submit} ) {
        $self->{submit} = [ $self->{submit} ]
            unless ref $self->{submit} eq "ARRAY";

        my @submit_temp = ();
        foreach my $submit ( @{ $self->{submit} } ) {

       # If we have been handed an action moniker to submit, just submit that.
            if ( !ref($submit) ) { push @submit_temp, $submit }

            # We've been handed a Jifty::Action to submit
            elsif ( blessed($submit) ) {
                push @submit_temp, $submit->moniker;
                $self->register_action($submit);
            }

          # We've been handed a hashref which contains an action and arguments
            else {

           # Add whatever additional arguments they've requested to the button
                $args{parameters}{ $submit->{'action'}->form_field_name($_) }
                    = $submit->{arguments}{$_}
                    for keys %{ $submit->{arguments} };

                # Add the action's moniker to the submit
                push @submit_temp, $submit->{'action'}->moniker;
                $self->register_action($submit->{'action'});
            }
        }

        @{ $self->{submit} } = @submit_temp;
    }

    # Anything doing fragment replacement needs to preserve the
    # current state as well
    if ( grep { $self->$_ } $self->handlers_used or $self->preserve_state ) {
        my %state_vars = Jifty->web->state_variables;
        while ( my ( $key, $val ) = each %state_vars ) {
            if ( $key =~ /^region-(.*?)\.(.*)$/ ) {
                $self->region_argument( $1, $2 => $val );
            } elsif ( $key =~ /^region-(.*)$/ ) {
                $self->region_fragment( $1, $val );
            } else {
                $self->state_variable( $key => $val );
            }
        }
    }

    $self->parameter( $_ => $args{parameters}{$_} )
        for keys %{ $args{parameters} };

    return $self;
}

=head2 url [VALUE]

Gets or sets the page that the user will end up on after they click
the button.  Defaults to the current page.

=head2 label [VALUE]

Gets or sets the text on the clickable object.

=head2 escape_label [VALUE]

Gets or sets if the label is escaped.  This is only relevant for
objects that are rendered as HTML links.  The default is true.

=head2 continuation [VALUE]

Gets or sets the current continuation for the link.  Defaults to the
current continuation now, if there is one.  This may be either a
L<Jifty::Continuation> object, or the C<id> of such.

=head2 call [VALUE]

Gets or sets the continuation to call when the link is clicked.  This
will happen after actions have run, if any.  Like C<continuation>,
this may be a L<Jifty::Continuation> object or the C<id> of such.

=head2 returns [VALUE]

Gets or sets the return value mapping from the continuation.  See
L<Jifty::Request::Mapper> for details.

=head2 submit [VALUE]

Gets or sets the list of actions to run when the object is clicked.
This may be an array refrence or a single element; each element may
either be a moniker or a L<Jifty::Action>.  An undefined value submits
B<all> actions in the form, an empty list reference (the default)
submits none.

=head2 preserve_state [VALUE]

Gets or sets whether state variables are preserved across the link.
Defaults to true if there are any AJAX actions on the link, false
otherwise.

=head2 parameter KEY VALUE

Sets the given HTTP paramter named C<KEY> to the given C<VALUE>.

=cut

sub parameter {
    my $self = shift;
    my ( $key, $value ) = @_;
    $self->{parameters}{$key} = $value;
}

=head2 state_variable KEY VALUE

Sets the state variable named C<KEY> to C<VALUE>.

=cut

sub state_variable {
    my $self = shift;
    defined $self->call_trigger( 'before_state_variable', @_ )
        or return;    # if aborted by trigger

    my ( $key, $value, $fallback ) = @_;
    if ( defined $value and length $value ) {
        $self->{state_variable}{"J:V-$key"} = $value;
    } else {
        delete $self->{state_variable}{"J:V-$key"};
        $self->{fallback}{"J:V-$key"} = $fallback;
    }
}

=head2 region_fragment NAME PATH

Sets the path of the fragment named C<NAME> to be C<PATH>.

=cut

sub region_fragment {
    my $self = shift;
    my ( $region, $fragment ) = @_;

    my $name = ref $region ? $region->qualified_name : $region;
    my $defaults = Jifty->web->get_region($name);

    if ( $defaults and $fragment eq $defaults->default_path ) {
        $self->state_variable( "region-$name" => undef, $fragment );
    } else {
        $self->state_variable( "region-$name" => $fragment );
    }
}

=head2 region_argument NAME ARG VALUE

Sets the value of the C<ARG> argument on the fragment named C<NAME> to
C<VALUE>.

=cut

sub region_argument {
    my $self = shift;
    my ( $region, $argument, $value ) = @_;

    my $name     = ref $region ? $region->qualified_name : $region;
    my $defaults = Jifty->web->get_region($name);
    my $default  = $defaults ? $defaults->default_argument($argument) : undef;

    if (   ( not defined $default and not defined $value )
        or ( defined $default and defined $value and $default eq $value ) )
    {
        $self->state_variable( "region-$name.$argument" => undef, $value );
    } else {
        $self->state_variable( "region-$name.$argument" => $value );
    }

}

# Query-map any complex structures
sub _map {
    my %old_args = @_;
    my %new_args;

    while ( my ( $key, $val ) = each %old_args ) {
        my ( $new_key, $new_val )
            = Jifty::Request::Mapper->query_parameters( $key => $val );
        $new_args{$new_key} = $new_val;
    }

    return %new_args;
}

=head2 parameters

Returns the generic list of HTTP form parameters attached to the link as a hash.
Use of this is discouraged in favor or L</post_parameters> and
L</get_parameters>.

=cut

sub parameters {
    my $self = shift;

    my %parameters;

    if ( $self->returns ) {
        %parameters
            = Jifty::Request::Mapper->query_parameters( %{ $self->returns } );
        $parameters{"J:CREATE"} = 1;
        $parameters{"J:PATH"}   = Jifty::Web::Form::Clickable->new(
            url          => $self->url,
            parameters   => $self->{parameters},
            continuation => undef,
        )->complete_url;
    } else {
        %parameters = %{ $self->{parameters} };
    }

    %parameters = _map( %{ $self->{state_variable} || {} }, %parameters );

    $parameters{"J:CALL"} = $self->call
        if $self->call;

    $parameters{"J:C"} = $self->continuation
        if $self->continuation
        and not $self->call;

    return %parameters;
}

=head2 post_parameters

Returns the hash of parameters as they would be needed on a POST
request.

=cut

sub post_parameters {
    my $self = shift;

    my %parameters
        = ( _map( %{ $self->{fallback} || {} } ), $self->parameters );

    my $root = Jifty->web->request->request_uri;

    # Submit actions should only show up once
    my %uniq;
    $self->submit( [ grep { not $uniq{$_}++ } @{ $self->submit } ] )
        if $self->submit;

    # Add a redirect, if this isn't to the right page
    if ( $self->url ne $root and not $self->returns ) {
        Jifty::Util->require('Jifty::Action::Redirect');
        my $redirect = Jifty::Action::Redirect->new(
            arguments => { url => $self->url } );
        $parameters{ $redirect->register_name } = ref $redirect;
        $parameters{ $redirect->form_field_name('url') } = $self->url;
        $parameters{"J:ACTIONS"}
            = join( '!', @{ $self->submit }, $redirect->moniker )
            if $self->submit;
    } else {
        $parameters{"J:ACTIONS"} = join( '!', @{ $self->submit } )
            if $self->submit;
    }

    return %parameters;
}

=head2 get_parameters

Returns the hash of parameters as they would be needed on a GET
request.

=cut

sub get_parameters {
    my $self = shift;

    my %parameters = $self->parameters;

    return %parameters;
}

=head2 complete_url

Returns the complete GET URL, as it would appear on a link.

=cut

sub complete_url {
    my $self = shift;

    my %parameters = $self->get_parameters;

    my ($root) = Jifty->web->request->request_uri;
    my $url = $self->returns ? $root : $self->url;
    if (%parameters) {
        $url .= ( $url =~ /\?/ ) ? ";" : "?";
        $url .= Jifty->web->query_string(%parameters);
    }

    return $url;
}

sub _defined_accessor_values {
    my $self = shift;
    # Note we're walking around Class::Accessor here
    return { map { my $val = $self->{"_$_"} || $self->{$_}; defined $val ? ( $_ => $val ) : () }
            $self->SUPER::accessors };
}

=head2 as_link

Returns the clickable as a L<Jifty::Web::Form::Link>, if possible.
Use of this method is discouraged in favor of L</generate>, which can
better determine if a link or a button is more appropriate.

=cut

sub as_link {
    my $self = shift;

    my $args = $self->_defined_accessor_values;
    my $link = Jifty::Web::Form::Link->new(
        {   %$args,
            escape_label => $self->escape_label,
            url          => $self->complete_url,
            target       => $self->target,
            continuation => $self->_continuation,
            @_
        }
    );
    return $link;
}

sub _continuation {

    # continuation info used by the update() call on client side
    my $self = shift;
    if ( $self->call ) {
        return { 'type' => 'call', id => $self->call };
    }
    if ( $self->returns ) {
        return { 'create' => $self->url };
    }

    return {};
}

=head2 as_button

Returns the clickable as a L<Jifty::Web::Form::Field::InlineButton>,
if possible.  Use of this method is discouraged in favor of
L</generate>, which can better determine if a link or a button is more
appropriate.

=cut

sub as_button {
    my $self = shift;

    my $args  = $self->_defined_accessor_values;
    my $field = Jifty::Web::Form::Field->new(
        {   %$args,
            type         => 'InlineButton',
            continuation => $self->_continuation,
            title        => $self->tooltip,
            @_
        }
    );
    my %parameters = $self->post_parameters;

    $field->input_name(
        join "|",
        map      { $_ . "=" . $parameters{$_} }
            grep { defined $parameters{$_} } keys %parameters
    );
    $field->name( join '|', keys %{ $args->{parameters} } );
    $field->button_as_link( $self->render_as_link );

    return $field;
}

=head2 generate

Returns a L<Jifty::Web::Form::Field::InlineButton> or
I<Jifty::Web::Form::Link>, whichever is more appropriate given the
parameters.

=cut

## XXX TODO: This code somewhat duplicates hook-handling logic in
## Element.pm, in terms of handling shortcuts like
## 'refresh_self'. Some of the logic should probably be unified.

sub generate {
    my $self = shift;
    my $web = Jifty->web;
    for my $trigger ( $self->handlers_used ) {
        my $value = $self->$trigger;
        next unless $value;
        my @hooks = @{$value};
        for my $hook (@hooks) {
            next unless ref $hook eq "HASH";
            $hook->{region} ||= $hook->{refresh}
                || $web->qualified_region;

            my $region
                = ref $hook->{region}
                ? $hook->{region}
                : $web->get_region( $hook->{region} );

            if ( $hook->{replace_with} ) {
                my $currently_shown = '';
                if ($region) {

                    my $state_var = $web->request->state_variable(
                        "region-" . $region->qualified_name );
                    $currently_shown = $state_var->value if ($state_var);
                }

  # Toggle region if the toggle flag is set, and clicking wouldn't change path
                if (    $hook->{toggle}
                    and $hook->{replace_with} eq $currently_shown )
                {
                    $self->region_fragment( $hook->{region},
                        "/__jifty/empty" );

                } else {
                    $self->region_fragment( $hook->{region},
                        $hook->{replace_with} );
                }

            }
            $self->region_argument( $hook->{region}, $_ => $hook->{args}{$_} )
                for keys %{ $hook->{args} };
            if ( $hook->{submit} ) {
                $self->{submit} ||= [];
                for my $moniker ( @{ $hook->{submit} } ) {
                    my $action = $web->{'actions'}{$moniker};
                    $self->register_action($action);
                    $self->parameter( $action->form_field_name($_),
                        $hook->{action_arguments}{$moniker}{$_} )
                        for
                        keys %{ $hook->{action_arguments}{$moniker} || {} };
                }
                push @{ $self->{submit} }, @{ $hook->{submit} };
            }
        }
    }

    return (
        (          not( $self->submit )
                || @{ $self->submit }
                || $self->render_as_button
        )
        ? $self->as_button(@_)
        : $self->as_link(@_)
    );
}

=head2 register_action ACTION

Reisters the action if it isn't registered already, but only on the
link.  That is, the registration will not be seen by any other buttons
in the form.

=cut

sub register_action {
    my $self = shift;
    my ($action) = @_;
    return if Jifty->web->form->actions->{ $action->moniker };

    my $arguments = $action->arguments;
    $self->parameter( $action->register_name, ref $action );
    $self->parameter( $action->fallback_form_field_name($_),
        $action->argument_value($_) || $arguments->{$_}->{'default_value'} )
        for grep { $arguments->{$_}{constructor} } keys %{$arguments};
}

1;
