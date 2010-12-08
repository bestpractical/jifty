use warnings;
use strict;

package Jifty::Request::Mapper;

=head1 NAME

Jifty::Request::Mapper - Maps response values into arbitrary query
parameters

=head1 DESCRIPTION

C<Jifty::Request::Mapper> is used to insert values into parameters
that you can't know when you originally constructed the request.  The
prime example of this is a Create action to a View page -- where you
can't know what ID to supply to the View page until after the Create
action has run.  This problem can be fixed by establishing a mapping
between some part of the L<Jifty::Result> of the Create action, and
the ID query parameter.

=head1 METHODS

=head2 query_parameters HASH

Extended syntax for generating query parameters.  This is used by
L<Jifty::Web::Form::Clickable> for its C<parameters> argument, as well
as for C<results> of continuations.

Possible formats for each key => value pair in the C<HASH> are:

=over

=item C<< KEY => STRING >>

The simplest form -- the C<KEY> will have the literal value of the
C<STRING> supplied

=item C<< KEY => { result => ACTION } >>

The C<KEY> will take on the value of the content named C<KEY> from the
result of the C<ACTION>.  C<ACTION> may either be a L<Jifty::Action>
object, or a moniker thereof.

=item C<< KEY => { result => ACTION, name => STRING } >>

The C<KEY> will take on the value of the content named C<STRING> from
the result of the C<ACTION>.  C<ACTION> may either be a L<Jifty::Action>
object, or a moniker thereof.

=item C<< KEY => { request_argument => STRING } >>

The C<KEY> will take on the value of the argument named C<STRING> from
the request.

=item C<< KEY => { argument => ACTION } >>

The C<KEY> will take on the value of the argument named C<KEY> from
the C<ACTION>.  C<ACTION> may either be a L<Jifty::Action> object, or
a moniker thereof.

=item C<< KEY => { argument => ACTION. name => STRING } >>

The C<KEY> will take on the value of the argument named C<STRING> from
the C<ACTION>.  C<ACTION> may either be a L<Jifty::Action> object, or
a moniker thereof.

=back

C<result_of> and C<argument_to> are valid synonyms for C<result> and
C<argument>, above.

=cut

sub query_parameters {
    my $class = shift;

    my %parameters = @_;
    my %return;
    for my $key (keys %parameters) {
        if (ref $parameters{$key} eq "HASH") {
            my %mapping = %{$parameters{$key}};

            if ($mapping{request_argument}) {
                $return{"J:M-$key"} = join("`","A", $mapping{request_argument});
            }

            for (grep {/^(result(_of)?|argument(_to)?)$/} keys %mapping) {
                my $action  = $mapping{$_};
                my $moniker = ref $action ? $action->moniker : $action;
                # If $key is for an argument of an action, we want to
                # extract only the argument's name, and not just use
                # the whole encoded J:A:F-... string.
                my (undef, $a, undef) = Jifty::Request->parse_form_field_name($key);
                my $name = $mapping{name} || $a || $key;

                my $type = ($_ =~ /result/) ? "R" : "A";

                $return{"J:M-$key"} = join("`", $type, $moniker, $name);
            }
        } else {
            $return{$key} = $parameters{$key};
        }
    }

    return %return;
}


=head2 map PARAMHASH

Responsible for doing the actual mapping that L</query_parameters>
above sets up.  That is, takes magical query parameters and extracts
the values they were meant to have.

=over

=item destination

The C<key> from a query parameter

=item source

The C<value> of a query parameter

=item request

The L<Jifty::Request> object to pull action arguments from.  Defaults
to the current request.

=item response

The L<Jifty::Response> object to pull results from.  Defaults to the
current response.

=back

Returns a key => value pair.

=cut

sub map {
    my $class = shift;

    my %args = (
        source      => undef,
        destination => undef,
        request     => Jifty->web->request,
        response    => Jifty->web->response,
        @_
    );

    my @original = ($args{destination} => $args{source});

    # In case the source is a hashref, we force ourselves to go the
    # *other* direction first.
    ($args{destination}, $args{source}) = $class->query_parameters($args{destination} => $args{source});

    # Bail unless it's a mapping
    return ( @original )
        unless defined $args{destination} and $args{destination} =~ /^J:M-(.*)/;

    my $destination = $1;

    my @bits = split( /\`/, $args{source} );
    if ( $bits[0] ) {
        if ( $bits[0] eq "A" and @bits == 3 ) {
            # No such action -- value is undef
            return ( $destination => undef ) unless $args{request}->top_request->action( $bits[1] );
            # We have a value
            return ( $destination => $args{request}->top_request->action( $bits[1] )->argument( $bits[2] ) );
        } elsif ( $bits[0] eq "R" and @bits == 3 ) { 
            # No such action -- value is undef
            return ( $destination => undef ) unless $args{request}->top_request->action( $bits[1] );
            # Action exists but hasn't run yet -- defer until later
            return ( @original ) unless $args{response}->result( $bits[1] );
            # We have a value
            return ( $destination => $args{response}->result( $bits[1] )->content( $bits[2] ) );
        } elsif ( $bits[0] eq "A" and @bits == 2 ) {
            return ( $destination => $args{request}->arguments->{ $bits[1] } );
        }
    }
    # As a fallback, just set it to the value
    return ( $destination => $args{source} );

}


1;
