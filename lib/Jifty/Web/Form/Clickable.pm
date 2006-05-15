use warnings;
use strict;

package Jifty::Web::Form::Clickable;

=head1 NAME

Jifty::Web::Form::Clickable - Some item that can be clicked on --
either a button or a link.

=head1 DESCRIPTION

=cut

use base qw/Jifty::Web::Form::Element Class::Accessor::Fast/;

=head2 accessors

Clickable adds C<url>, C<escape_label>, C<continuation>, C<call>,
C<returns>, C<submit>, and C<preserve_state> to the list of accessors
and mutators, in addition to those offered by
L<Jifty::Web::Form::Element/accessors>.

=cut

sub accessors {
    shift->SUPER::accessors,
        qw(url escape_label tooltip continuation call returns submit preserve_state button);
}
__PACKAGE__->mk_accessors(
    qw(url escape_label tooltip continuation call returns submit preserve_state button)
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
where the return value is pulled from.  See L<Jifty::Request::Mapper>
for details.

=item submit

A list of actions to run when the object is clicked.  This may be an
array refrence of a single element; each element may either be a
moniker or a L<Jifty::Action>.  An undefined value submits B<all>
actions in the form, an empty list reference (the default) submits
none.

=item preserve_state

A boolean; whether state variables are preserved across the link.
Defaults to true if there are any AJAX actions on the link, false
otherwise.

=item parameters

A hash reference of query parameters that go on the link or button.
These will end up being submitted exactly like normal query
parameters.

=item button

By default, Jifty will attempt to make the clickable into a link
rather than a button, if there are no actions to run on submit.
Providing a true value for C<button> forces L<generate> to produce a
L<Jifty::Web::Form::Clickable::InlineButton> instead of a
L<Jifty::Web::Form::Link>.  Note that providing a false value will
B<not> guarantee that you get a link, as a button may be necessary
based on the presence of the L</submit> parameter.

=item Anything from L<Jifty::Web::Form::Element>

=back

=cut

sub new {
    my $class = shift;
    my $self  = bless {}, $class;

    my ($root) = $ENV{'REQUEST_URI'} =~ /([^\?]*)/;

    my %args = (
        url            => $root,
        label          => 'Click me!',
        tooltip        => '',
        class          => '',
        escape_label   => 1,
        continuation   => Jifty->web->request->continuation,
        submit         => [],
        preserve_state => 0,
        parameters     => {},
        button         => 0,
        @_,
    );

    $self->{parameters} = {};

    for (qw/continuation call/) {
        $args{$_} = $args{$_}->id if $args{$_} and ref $args{$_};
    }

    if ( $args{submit} ) {
        $args{submit} = [ $args{submit} ] unless ref $args{submit} eq "ARRAY";
        $args{submit}
            = [ map { ref $_ ? $_->moniker : $_ } @{ $args{submit} } ];

        # If they have an onclick, add any and all submit actions to the onclick's submit list
        if ($args{onclick}) {
            $args{onclick} = [ (ref $args{onclick} eq "ARRAY" ? @{ $args{onclick} } : $args{onclick}), map { submit => $_ }, @{$args{submit}} ];
        }
    }

    for my $field ( $self->accessors() ) {
        $self->$field( $args{$field} ) if exists $args{$field};
    }

    # Anything doing fragment replacement needs to preserve the
    # current state as well
    if ( grep { $self->$_ } $self->handlers or $self->preserve_state ) {
        for ( Jifty->web->request->state_variables ) {
            if ( $_->key =~ /^region-(.*?)\.(.*)$/ ) {
                $self->region_argument( $1, $2 => $_->value );
            } elsif ( $_->key =~ /^region-(.*)$/ ) {
                $self->region_fragment( $1, $_->value );
            } else {
                $self->state_variable( $_->key => $_->value );
            }
        }
    }

    $self->parameter( $_ => $args{parameters}{$_} )
        for keys %{ $args{parameters} };

    return $self;
}

=head2 url

Sets the page that the user will end up on after they click the
button.  Defaults to the current page.

=head2 label

The text on the clickable object.

=head2 escape_label

If set to true, HTML escapes the content of the label before
displaying it.  This is only relevant for objects that are rendered as
HTML links.  The default is true.

=head2 continuation

The current continuation for the link.  Defaults to the current
continuation now, if there is one.  This may be either a
L<Jifty::Continuation> object, or the C<id> of such.

=head2 call

The continuation to call when the link is clicked.  This will happen
after actions have run, if any.  Like C<continuation>, this may be a
L<Jifty::Continuation> object or the C<id> of such.

=head2 returns

Passing this parameter implies the creation of a continuation when the
link is clicked.  It takes an anonymous hash of return location to
where the return value is pulled from.  See L<Jifty::Request::Mapper>
for details.

=head2 submit

A list of actions to run when the object is clicked.  This may be an
array refrence of a single element; each element may either be a
moniker of a L<Jifty::Action>.  An undefined value submits B<all>
actions in the form, an empty list reference (the default) submits
none.

=head2 preserve_state

A boolean; whether state variables are preserved across the link.
Defaults to true if there are any AJAX actions on the link, false
otherwise.

=head2 parameter KEY VALUE

Sets the given HTTP paramter named C<KEY> to the given C<VALUE>.

=cut

sub parameter {
    my $self = shift;
    my ( $key, $value ) = @_;
    ($key, $value) = Jifty::Request::Mapper->query_parameters($key => $value);
    $self->{parameters}{$key} = $value;
}

=head2 state_variable KEY VALUE

Sets the state variable named C<KEY> to C<VALUE>.

=cut

sub state_variable {
    my $self = shift;
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

    my $name = ref $region ? $region->qualified_name : $region;
    my $defaults = Jifty->web->get_region($name);

    if ( $defaults and $value eq $defaults->default_argument($argument) ) {
        $self->state_variable( "region-$name.$argument" => undef, $value );
    } else {
        $self->state_variable( Jifty::Request::Mapper->query_parameters( "region-$name.$argument" => $value ) );
    }

}

=head2 parameters

Returns the generic list of parameters attached to the link as a hash.
Use of this is discouraged in favor or L</post_parameters> and
L</get_parameters>.

=cut

sub parameters {
    my $self = shift;

    my %parameters;

    if ( $self->returns ) {
        %parameters = Jifty::Request::Mapper->query_parameters( %{ $self->returns } );
        $parameters{"J:CREATE"} = 1;
        $parameters{"J:PATH"} = Jifty::Web::Form::Clickable->new( url => $self->url,
                                                                  parameters => $self->{parameters},
                                                                  continuation => undef,
                                                                )->complete_url;
    } else {
        %parameters = %{ $self->{parameters} };        
    }

    %parameters = ( %{$self->{state_variable} || {}}, %parameters );

    $parameters{"J:CALL"} = $self->call
        if $self->call;

    $parameters{"J:C"} = $self->continuation
        if $self->continuation
        and not $self->call;

    return %parameters;
}

=head2 post_parameters

The hash of parameters as they would be needed on a POST request.

=cut

sub post_parameters {
    my $self = shift;

    my %parameters = ( %{ $self->{fallback} || {} }, $self->parameters );

    my ($root) = $ENV{'REQUEST_URI'} =~ /([^\?]*)/;

    # Add a redirect, if this isn't to the right page
    if ( $self->url ne $root and not $self->returns ) {
        require Jifty::Action::Redirect;
        my $redirect = Jifty::Action::Redirect->new(
            arguments => { url => $self->url } );
        $parameters{ $redirect->register_name } = ref $redirect;
        $parameters{ $redirect->form_field_name('url') } = $self->url;
        $parameters{"J:ACTIONS"} = join( ';', @{ $self->submit }, $redirect->moniker )
          if $self->submit;
    } else {
        $parameters{"J:ACTIONS"} = join( ';', @{ $self->submit } )
          if $self->submit;
    }

    return %parameters;
}

=head2 get_parameters

The hash of parameters as they would be needed on a GET request.

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

    my ($root) = $ENV{'REQUEST_URI'} =~ /([^\?]*)/;
    my $url = $self->returns ? $root : $self->url;
    if (%parameters) {
        $url .= ( $url =~ /\?/ ) ? ";" : "?";
        $url .= Jifty->web->query_string(%parameters);
    }

    return $url;
}

=head2 as_link

Returns the clickable as a L<Jifty::Web::Form::Link>, if possible.
Use of this method is discouraged in favor of L</generate>, which can
better determine if a link or a button is more appropriate.

=cut

sub as_link {
    my $self = shift;

    my %args;
    $args{$_} = $self->$_
        for grep { defined $self->$_ } $self->SUPER::accessors;
    my $link = Jifty::Web::Form::Link->new(
        %args,
        escape_label => $self->escape_label,
        url          => $self->complete_url,
        @_
    );
    return $link;
}

=head2 as_button

Returns the clickable as a L<Jifty::Web::Form::Field::InlineButton>,
if possible.  Use of this method is discouraged in favor of
L</generate>, which can better determine if a link or a button is more
appropriate.

=cut

sub as_button {
    my $self = shift;

    my %args;
    $args{$_} = $self->$_
        for grep { defined $self->$_ } $self->SUPER::accessors;
    my $field = Jifty::Web::Form::Field->new(
        %args,
        type => 'InlineButton',
        @_
    );
    my %parameters = $self->post_parameters;

    $field->input_name(
        join "|",
        map      { $_ . "=" . $parameters{$_} }
            grep { defined $parameters{$_} } keys %parameters
    );
    $field->name( join '|', keys %{ $args{parameters} } );

    return $field;
}

=head2 generate

Returns a L<Jifty::Web::Form::Field::InlineButton> or
I<Jifty::Web::Form::Link>, whichever is more appropriate given the
parameters.

=cut

sub generate {
    my $self = shift;

    for my $trigger ( $self->handlers ) {
        my $value = $self->$trigger;
        next unless $value;
        my @hooks = ref $value eq "ARRAY" ? @{$value} : ($value);
        for my $hook (@hooks) {
            $hook->{region} ||= $hook->{refresh} || Jifty->web->qualified_region;
            $hook->{args}   ||= {};

            $self->region_fragment( $hook->{region}, $hook->{replace_with} )
                if $hook->{replace_with};
            $self->region_argument( $hook->{region}, $_ => $hook->{args}{$_} )
                for keys %{ $hook->{args} };
            if ( $hook->{submit} ) {
                $self->{submit} ||= [];
                $hook->{submit} = [ $hook->{submit} ] unless ref $hook->{submit} eq "ARRAY";
                push @{ $self->{submit} },
                    map { ref $_ ? $_->moniker : $_ } @{ $hook->{submit} };
            }
        }
    }

    return ( ( not( $self->submit ) || @{ $self->submit } || $self->button )
        ? $self->as_button(@_)
        : $self->as_link(@_) );
}

1;
