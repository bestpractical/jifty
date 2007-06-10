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
is then called, and then the filled-in request is then passed to the
L<Jifty::Dispatcher>.

=cut


use Storable 'dclone';

use base qw/Class::Accessor::Fast/;

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
                @_
               );

    # We don't want refs
    $args{parent} = $args{parent}->id
      if $args{parent} and ref $args{parent};

    # We're getting most of our properties from the arguments
    for (keys %args) {
        $self->$_($args{$_}) if $self->can($_);
    }

    # Generate a hopefully unique ID
    # FIXME: use a real ID
    my $key = Jifty->web->serial . "_" . int(rand(10)) . int(rand(10)) . int(rand(10)) . int(rand(10)) . int(rand(10)) . int(rand(10));
    $self->id($key);

    # Save it into the session
    Jifty->web->session->set_continuation($key => $self);

    return $self;
}

=head2 return_path_matches

Returns true if the continuation matches the current request's path,
and it would return to its caller in this context.  This can be used
to ask "are we about to call a continuation?"

=cut

sub return_path_matches {
    my $self = shift;
    my $called_uri = $ENV{'REQUEST_URI'};
    my $request_path = $self->request->path;

    # XXX TODO: WE should be using URI canonicalization

    my $escape;
    $called_uri =~ s{/+}{/}g;
    $called_uri = Encode::encode_utf8($called_uri);
    $called_uri = $escape while $called_uri ne ($escape = URI::Escape::uri_unescape($called_uri));
    $request_path =~ s{/+}{/}g; 
    $request_path = Encode::encode_utf8($request_path);
    $request_path = $escape while $request_path ne ($escape = URI::Escape::uri_unescape($request_path));

    return $called_uri =~ /^\Q$request_path\E[?&;]J:RETURN=@{[$self->id]}$/;
}

=head2 call

Call the continuation; this is generally done during request
processing, after actions have been run.
L<Jifty::Request::Mapper>-controlled values are filled into the stored
request based on the current request and response.  During the
process, another continuation is created, with the filled-in results
of the current actions included, and the browser is redirected to the
proper path, with that continuation.

=cut

sub call {
    my $self = shift;

    Jifty->log->debug("Redirect to @{[$self->request->path]} via continuation");
    if (Jifty->web->request->argument('_webservice_redirect')) {
	# for continuation - perform internal redirect under webservices.
        Jifty->web->webservices_redirect($self->request->path);
	return;
    }
    # If we needed to fix up the path (it contains invalid
    # characters) then warn, because this may cause infinite
    # redirects
    Jifty->log->warn("Redirect to '@{[$self->request->path]}' contains unsafe characters")
      if $self->request->path =~ m{[^A-Za-z0-9\-_.!~*'()/?&;+]};

    # Clone our request
    my $request = $self->request->clone;

    # Fill in return value(s) into correct part of $request
    $request->do_mapping;

    my $response = $self->response;
    # If the current response has results, we need to pull them
    # in.  For safety, monikers from the saved continuation
    # override those from the request prior to the call
    if (Jifty->web->response->results) {
        $response = dclone(Jifty->web->response);
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
    Jifty->web->_redirect($next->request->path . "?J:RETURN=" . $next->id);
    return 1;
}

=head2 return

Returns from the continuation by pulling out the stored request, and
setting that to be the active request.  This shouldn't need to be
called by hand -- use L<Jifty::Request/return_from_continuation>,
which ensures that all requirements are ment before it calls this.

=cut

sub return {
    my $self = shift;

    # Pull state information out of the continuation and set it
    # up; we use clone so that the continuation itself is
    # immutable.
    Jifty->web->response(dclone($self->response));

    # Run any code in the continuation
    $self->code->(Jifty->web->request)
      if $self->code;

    # Set the current request to the one in the continuation
    return Jifty->web->request($self->request->clone);
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
