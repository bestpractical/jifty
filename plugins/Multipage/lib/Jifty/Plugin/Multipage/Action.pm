use warnings;
use strict;

package Jifty::Plugin::Multipage::Action;

use Moose::Role;

=head1 NAME

Jifty::Plugin::Multipage::Action - Actions stretched across multiple
pages

=head1 DESCRIPTION

C<Jifty::Plugin::Multipage::Action> is a L<Moose::Role> mixin for
actions which span across multiple pages, in a "wizard" workflow.
Each page but the last gets a chance to validate all of the inputs yet
entered, and transparently remembers inputs from previous pages.
Since the information is stored in continuations, not directly on
sessions, it is "back"-button compatible, and the same user can be in
the middle of multiple instances of the same multipage action at once.

The action must have the same moniker on all pages which it appears.
Field validators on the action must be prepared to be called with no
value, if the argument field has not been seen by the user yet.  That
is, if a multipage action has three fields, labelled C<A>, C<B>, and
C<C>, one on each page, then L</validate> will first be called with
only a value for C<A>, for the first page; then with C<A> and C<B>,
for the second page; then with C<A>, C<B>, and C<C> for the third
page; then it will be run.

=cut

=head1 METHODS

=head2 new

Sets up the multipage action, by examining previous continuations for
this action.  If it finds any, it populates the argument values using
them, most recent ones taking precedence.

=cut

around 'new' => sub {
    my ($next, $class, %args) = @_;
    my $self = $next->($class, %args);

    # Fetch any arguments from a passed in request
    my @actions;
    push @actions, Jifty->web->request->action( $self->moniker )
      if Jifty->web->request->action( $self->moniker );

    # Also, all earlier versions of this action in the continuation tree
    my $cont = Jifty->web->request->continuation;
    while ( $cont and $cont->request->action( $self->moniker ) ) {
        push @actions, $cont->request->action( $self->moniker );
        $self->{top_continuation} = $cont;
        $cont = $cont->parent;
        $cont = Jifty->web->session->get_continuation($cont) if defined $cont;
    }

    # Extract their arguments, earliest to latest
    my %earlier;
    for (reverse grep {$_->arguments} @actions) {
        %earlier = (%earlier, %{$_->arguments});
    }

    # Setup the argument values with the new_action arguments taking precedent
    $self->argument_values( { %earlier, %{ $args{'arguments'} } } );

    # Track how an argument was set, again new_action args taking precedent
    $self->values_from_request({});
    $self->values_from_request->{$_} = 1 for keys %earlier;
    $self->values_from_request->{$_} = 0 for keys %{ $args{'arguments' } };

    return $self;
};

=head2 validate

If the action doesn't validate, modify the request to not be a
continuation push.  Otherwise, mark the action as inactive, so it
doesn't get run if the continuation somehow gets called.

=cut

after 'validate' => sub {
    my $self = shift;
    if ($self->result->failure) {
        Jifty->web->request->continuation_path(undef);
    } elsif (Jifty->web->request->continuation_path) {
        Jifty->web->request->action( $self->moniker )->active(0);
    }
};

=head2 top_continuation

Returns the topmost continuation which contains this multipage action.

=cut

has top_continuation => ( is => 'rw', isa => 'Jifty::Continuation' );

=head2 next_page_button url => PATH, [ARGS]

Acts like L<Jifty::Action/button>, except with appropriate defaults to
move to the next page in the action.  Failure to validate means the
user is kept on the same page.

=cut

sub next_page_button {
    my $self = shift;
    my %args = @_;
    confess "No 'url' passed to next_page_button for @{[ref $self]}"
      unless $args{url};

    # We do this munging so that we don't attempt a registration as part of the redirect
    my %returns;
    $returns{$self->form_field_name($_)} = $args{arguments}{$_}
        for keys %{$args{arguments} || {}};
    delete $args{arguments};

    return $self->button(
        register => 1,
        returns => \%returns,
        label => "Next",
        %args,
    );
}

=head2 finish_button [ARGS]

Acts like L<Jifty::Action/button>, except with appropriate defaults to
cause the action to run if it validates.  Failure to validate means
the user is kept on the same page.

Note: Unlike most uses of continuations in the Jifty core, simply
I<rendering> this button creates a continuation.

=cut

sub finish_button {
    my $self = shift;
    my %args = @_;
    my $top  = $self->top_continuation;

    my $req;
    if ( $args{url} ) {
        $req = Jifty::Request->new( path => delete $args{url} );
    } else {
        $req = $top->request;
        $req->remove_action( $self->moniker );
    }
    my $return = Jifty::Continuation->new(
        request  => $req,
        response => Jifty::Response->new,
        parent   => $top->parent
    );
    return $self->button( call => $return, label => "Finish", %args );
}

=head2 cancel_button [ARGS]

Acts like L<Jifty::Action/button>, except with appropriate defaults to
return the user to the page where the multipage action started.

=cut

sub cancel_button {
    my $self = shift;
    my %args;
    return Jifty->web->link( call => $self->top_continuation, label => "Cancel", as_button => 1, %args );
}

1;
