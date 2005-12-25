use warnings;
use strict;

=head1 NAME

Jifty::Action::Redirect - Redirect the browser

=cut

package Jifty::Action::Redirect;
use base qw/Jifty::Action/;

=head2 new

By default, redirect actions happen as late as possible in the run
order.  Defaults the L<Jifty::Action/order> to be 100 so it runs later
than most actions.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    # XXX TODO This is wrong -- it should be -1 or some equivilent, so
    # it is sorted last all the time.
    $self->order(100) unless defined $self->order;
    return $self;
}

=head2 arguments

The only argument to redirect is the C<url> to redirect to.

=cut

sub arguments {
        {
            url => { constructor => 1 },
        }

}

=head2 take_action

If the other actions in the request have been a success so far,
redirects to the provided C<url>.  The redirect preserves all of the
L<Jifty::Result>s for this action, in case the destination page wishes
to inspect them.

=cut

sub take_action {
    my $self = shift;
    return 1 unless ($self->argument_value('url'));
    return 0 unless Jifty->web->response->success;

    my $page = $self->argument_value('url');

    Jifty->web->next_page($page);
    return 1;
}

1;

