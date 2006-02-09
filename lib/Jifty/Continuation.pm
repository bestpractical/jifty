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

Continuations store a L<Jifty::Request> object and the
L<Jifty::Response> object for the request.  They can also store
arbitrary code to be run when the continuation is called.

Continuations can also be arbitrarily nested.  This means that
returning from one continuation will drop you into the continuation
that is one higher in the stack.

Continuations are generally created just before their request would
take effect, activated by the presence of certain query parameters.
The rest of the request is saved, its execution to be continued at a
later time.

Continuations are run after any actions have run.  When a continuation
is run, it restores the request that it has saved away into it, and
pulls into that request the values any return values that were
specified when it was created.  The continuations code block, if any,
is then called, and then the filled-in request is then run
L<Jifty::Web/handle_request>.

=cut

use Jifty::Everything;
use Clone;

use base qw/Class::Accessor/;

__PACKAGE__->mk_accessors(qw(id parent
                             request response code
                             ));

=head2 new PARAMHASH

Saves a continuation at the current state.  Possible arguments in the
C<PARAMHASH>:

=over

=item parent

A L<Jifty::Continuation> object, or the C<id> of one.  This represents
the continuation that this continuation should return to when it is
called.  Defaults to the current continuation of the current
L<Jifty::Request>.

=item request

The L<Jifty::Request> object to save away.  Defaults to an empty
L<Jifty::Request> object.

=item response

The L<Jifty::Response> object that will be loaded up when the
continuation is run.  Most of the time, the response isn't stored in
the continuation, since the continuation was saved away B<before> the
actions got run.  In the case when continuations are used to preserve
state across a redirect, however, we tuck the L<Jifty::Response> value
of the previous request into the continuation as well.  Defaults to an
empty L<Jifty::Response> object.

=item code

An optional subroutine reference to evaluate when the continuation is
called.

=item clone

There is a interface to support continuation "cloning," a process
which is useful to creating multi-page wizards and the like.  However,
this feature is still very much in flux; the documentation is waiting
for the interface to settle down a bit before being written.

=back

=cut

sub new {
    my $class = shift;
    my $self = bless { }, $class;

    my %args = (
                parent   => Jifty->web->request->continuation,
                request  => Jifty::Request->new(),
                response => Jifty::Response->new(),
                code     => undef,
                clone    => undef,
                @_
               );

    # We don't want refs
    $args{parent} = $args{parent}->id
      if $args{parent} and ref $args{parent};

    # We're cloning most of our attributes from a previous continuation
    if ($args{clone} and Jifty->web->session->get_continuation($args{clone})) {
        $self = Clone::clone(Jifty->web->session->get_continuation($args{clone}));
        for (grep {/^J:A/} keys %{$args{request}->arguments}) {
            $self->request->argument($_ => $args{request}->arguments->{$_});
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
    Jifty->web->session->set_continuation($key => $self);

    return $self;
}

=head2 call

Call the continuation; this is generally done during request
processing, after an actions have been run.
L<Jifty::Request::Mapper>-controlled values are filled into the stored
request based on the current request and response.  If an values
needed to be filled in, then *another* continuation is created, with
the filled-in values included, and the browser is redirected there.
This is to ensure that we end up at the correct request path, while
keeping continuations immutable and maintaining all of the request
state that we need.

=cut

sub call {
    my $self = shift;

    if (defined $self->request->path and $ENV{REQUEST_URI} ne $self->request->path . "?J:CALL=" . $self->id) {
        # Clone our request
        my $request = Clone::clone($self->request);
        
        # Fill in return value(s) into correct part of $request
        $request->do_mapping;

        my $response = $self->response;
        # If the current response has results, we need to pull them
        # in.  For safety, monikers from the saved continuation
        # override those from the request prior to the call
        if (Jifty->web->response->results) {
            $response = Clone::clone(Jifty->web->response);
            my %results = $self->response->results;
            $response->result($_ => $results{$_}) for keys %results;
        }
        
        # Make a new continuation with that request
        my $next = Jifty::Continuation->new(parent => $self->parent, 
                                            request => $request,
                                            response => $response,
                                            code => $self->code,
                                           );
        $next->request->continuation(Jifty->web->session->get_continuation($next->parent))
          if defined $next->parent;

        # Redirect to right page if we're not there already
        Jifty->web->_redirect($next->request->path . "?J:CALL=" . $next->id);
    } else {
        # Pull state information out of the continuation and set it
        # up; we use clone so that the continuation itself is
        # immutable.  It is vaguely possible that there are results in
        # the response already (set up by the dispatcher) so we place
        # results from the continuation's response into the existing
        # response only if it wouldn't clobber something.
        my %results = $self->response->results;
        for (keys %results) {
            next if Jifty->web->response->result($_);
            Jifty->web->response->result($_,Clone::clone($results{$_}));
        }

        # Run any code in the continuation
        $self->code->(Jifty->web->request)
          if $self->code;

        # Enter the request in the continuation, and handle it
        Jifty->web->request(Clone::clone($self->request));
        Jifty->web->handle_request();

        # Now we want to skip the rest of the
        # Jifty::Web->handle_request that we were called from.  Pop up
        # to the dispatcher
        Jifty::Dispatcher::next_show();
    }

}

=head2 delete

Remove the continuation, and any continuations that would return to
its scope, from the session.

=cut

sub delete {
    my $self = shift;

    # Remove all continuations that point to me
    $_->delete for grep {$_->parent eq $self->id} values %{Jifty->web->session->continuations};

    # Finally, remove me from the list of continuations
    Jifty->web->session->remove_continuation($self->id);

}

1;
