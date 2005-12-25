use warnings;
use strict;

package Jifty::Continuation;

=head1 NAME

Jifty::Continuation - Allows for basic continuation-based programming

=head1 DESCRIPTION

C<Jifty::Continuation> wraps up the information about a context that
might have been expecting some sort of answer.  It allows one to
re-visit that context later by providing the continuation again.
Continuations are stored on the user's session.

Continuations store a L<Jifty::Request> object, the contents of the
mason C<notes> hash, and the L<Jifty::Response> object for the
request.

Continuations can also be arbitrarily nested.  This means that
returning from one continuation may drop you into the continuation
that is one higher in the stack.

Continuations are generally created just before their request would
take effect, activated by the presence of certain query parameters.
The rest of the request is saved, its execution to be continued at a
later time.

Continuations are run after any actions have run.  When a continuation
is run, it restores the request that it has saved away into it, and
pulls into that request the values any return values that were
specified when it was created.  This filled-in request is then run
using L<Jifty::Web/handle_request>.

=cut

use Jifty::Everything;
use Clone;

use base qw/Class::Accessor/;

__PACKAGE__->mk_accessors(qw(id parent
                             request notes response code
                             ));

=head2 new PARAMHASH

Saves a continuation at the current state.  Possible arguments in the
C<PARAMHASH>:

=over

=item request

The L<Jifty::Request> object to save away.  This parameter is required.

=item parent

The id of a continuation that this continuation should return to.

=item response

The L<Jifty::Response> object that will be loaded up when the
continuation is run.  Most of the time, the response isn'at stored in
the continuation, since the continuation was saved away B<before> the
actions got run.  In the case when continuations are used to preserve
state across a redirect, however, we tuck the L<Jifty::Result> value
of the previous request into the continuation as well.

=item notes

An anonymous hash of the contents of the
L<HTML::Mason::Request/notes>.

=back

=cut

sub new {
    my $class = shift;
    my $self = bless { return_locations => [], notes => {}}, $class;

    my %args = (
                request  => Jifty::Request->new(),
                notes    => Jifty->web->mason->notes,
                response => Jifty::Response->new(),
                parent   => Jifty->web->request->continuation,
                code     => undef,
                clone    => undef,
                @_
               );

    # We don't want refs
    $args{parent} = $args{parent}->id
      if $args{parent} and ref $args{parent};

    # We're cloning most of our attributes from a previous continuation
    if ($args{clone} and Jifty->web->session->{continuations}{$args{clone}}) {
        $self = Clone::clone(Jifty->web->session->{continuations}{$args{clone}});
        for (grep {/^J:A/} keys %{$args{request}->arguments}) {
            $self->request->merge_param($_ => $args{request}->arguments->{$_});
        }
        $self->response($args{response});
    } else {
        delete $args{clone};
        # We're getting most of our properties from the arguments
        for (keys %args) {
            $self->$_($args{$_}) if $self->can($_);
        }
    }

    # Generate a hopefully unique ID
    # FIXME: use a real ID
    my $key = Jifty->web->serial . "_" . int(rand(10)) . int(rand(10)) . int(rand(10)) . int(rand(10)) . int(rand(10)) . int(rand(10));
    $self->id($key);

    # Save it into the session
    Jifty->web->session->{'continuations'}{$key} = $self;
    Jifty->web->save_session;

    return $self;
}

=head2 return_location FROM TO

Establishes a mapping between the output at the end of this series of
requests, and what parts of the request in the continuation consume
that information.  That is, the information that, on the page that we
jump back into this continuation from, the C<moose> form field should
get inserted into the C<foo> field of the C<bar> action.

The C<FROM> is one of the forms:

=over

=item R-I<moniker>-I<name>

In the I<moniker> action, the return value content named I<name>.

=item A-I<moniker>-I<argument>

In the I<moniker> action, the form field argument I<argument>.

=item A-I<name>

The query parameter named I<name>.

=item I<anything else>

Anything else is treated as a constant

=back

The value is copied from the named C<FROM> position, and placed into
the query parameter specified by C<TO>.
L<Jifty::Action/form_field_name> is often used to specify the C<TO>
location.

=cut

# TODO: Need better way of dealing with FROM
sub return_location {
    my $self = shift;
    my ($destination, $source) = @_;
    if ($source =~ /R-(.*?)-(.*)/) {
        push @{$self->{return_locations}}, {return => $2, moniker => $1, destination => $destination};
    } elsif ($source =~ /A-(.*?)-(.*)/) {
        push @{$self->{return_locations}}, {argument => $2, moniker => $1, destination => $destination};
    } elsif ($source =~ /A-(.*)/) {
        push @{$self->{return_locations}}, {argument => $1, destination => $destination};
    } elsif (defined $source and length $source) {
        push @{$self->{return_locations}}, {constant => $source, destination => $destination};
    }
}

=head2 call

Call the continuation; this is generall done during request
processing, after an actions have been run.  Values previously
specified with L</return_location> are filled into the stored request
from the current request and response.  If an values needed to be
filled in, then et *another* continuation is created, with the
filled-in values included, and the browser is redirected there.  This
is to ensure that we end up at the correct request path, while
maintaining all of the request state that we need.

=cut

sub call {
    my $self = shift;

    if (defined $self->request->path and $ENV{REQUEST_URI} ne $self->request->path . "?J:CALL=" . $self->id) {

        # Keep track of if we generated a new continuation
        my $changed = 0;

        # Clone our request
        my $request = Clone::clone($self->request);
        
        # Fill in return value(s) into correct part of $request
        for my $return (@{$self->{return_locations}}) {
            if ($return->{return}) {
                next unless Jifty->web->response->result($return->{moniker});
                $request->merge_param($return->{destination} => Jifty->web->response->result($return->{moniker})->content($return->{return}));
                $changed = 1;
            } elsif ($return->{moniker}) {
                next unless Jifty->web->request->action($return->{moniker});
                $request->merge_param($return->{destination} => Jifty->web->request->action($return->{moniker})->argument($return->{argument}));
                $changed = 1;
            } elsif ($return->{argument}) {
                next unless defined Jifty->web->request->arguments->{$return->{argument}};
                $request->merge_param($return->{destination} => Jifty->web->request->arguments->{$return->{argument}});
                $changed = 1;
            } else {
                $request->merge_param($return->{destination} => $return->{constant});
                $changed = 1;
            }
        }

        my $response = $self->response;
        # If the current response has results, we need to pull them
        # in.  For safety, monikers from the saved continuation
        # override those from the request prior to the call
        if (Jifty->web->response->results) {
            $response = Clone::clone(Jifty->web->response);
            my %results = $self->response->results;
            $response->result($_ => $results{$_}) for keys %results;
            $changed = 1;
        }
        

        # Only make a new continuation if we filled in values
        my $next = $self;
        if ($changed) {
            # Make a new continuation with that request
            $next = Jifty::Continuation->new(parent => $self->parent, 
                                             request => $request,
                                             response => $response,
                                             notes => $self->notes,
                                             code => $self->code,
                                            );
            $next->request->continuation(Jifty->web->session->{'continuations'}{$next->parent})
              if defined $next->parent;
            Jifty->web->save_session;
        }

        # Redirect to right page if we're not there already
        Jifty->web->mason->redirect($next->request->path . "?J:CALL=" . $next->id);
    } else {
        # Pull state information out of the continuation and set it
        # up; we use clone so that the continuation itself is
        # immutable.

        # TODO: maybe not use clone?  Use something happier?
        Jifty->web->response( Clone::clone($self->response) ) if $self->response;
        %{Jifty->web->mason->notes} = %{$self->notes};
        $self->code->(Jifty->web->request)
          if $self->code;
        Jifty->web->_internal_request( Clone::clone($self->request) );
    }

}

=head2 delete

Remove the continuation, and any continuations that would return to
its scope, from the session.

=cut

sub delete {
    my $self = shift;

    # Remove all continuations that point to me
    $_->delete for grep {$_->parent eq $self->id} values %{Jifty->web->session->{'continuations'}};

    # Finally, remove me from the list of continuations
    delete Jifty->web->session->{'continuations'}{$self->id};

    Jifty->web->save_session;
}

1;
