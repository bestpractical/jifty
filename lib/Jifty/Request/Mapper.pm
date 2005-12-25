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

Possible syntaxes for each key => value pair in the C<HASH> are:

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
            if ($mapping{result} or $mapping{result_of}) {
                # Pulling result of action
                my $action = $mapping{result} || $mapping{result_of};
                $action = $action->moniker if ref $action;
                my $name = $mapping{name} || $key;
                $return{"J:M-$key"} = "R-$action-$name";
            } elsif ($mapping{argument} or $mapping{argument_to}) {
                # Pulling argument of action
                my $action = $mapping{argument} || $mapping{argument_to};
                $action = $action->moniker if ref $action;
                my $name = $mapping{name} || $key;
                $return{"J:M-$key"} = "A-$action-$name";
            } else {
                warn "Don't know what to do with ".YAML::Dump(\%mapping);
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
the values they were ment to have.

=over

=item destination

The C<key> from a query parameter

=item source

The C<value> of a query parameter

=item request

The L<Jifty::Request> object to pull action arguments from.  Defauts
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

    return ($args{destination} => $args{source}) unless $args{destination} =~ /^J:M-(.*)/;

    my $destination = $1;

    if ($args{source} =~ /^A-([^-]+)-(.*)/) {
        return ($destination => $args{request}->action($1) ? $args{request}->action($1)->argument($2) : undef);
    } elsif ($args{source} =~ /^R-([^-]+)-(.*)/) {
        return ($destination => $args{response}->result($1) ? $args{response}->result($1)->content($2) : undef);
    } elsif ($args{source} =~ /^A-(.*)/) {
        return ($destination => $args{request}->arguments->{$1});
    } else {
        return ($destination => $args{source});
    }
    
}


1;
