use warnings;
use strict;

=head1 NAME

Jifty::Action::Redirect - Redirect the browser

=head1 SYNOPSIS

  Jifty->web->new_action(
      class => 'Redirect',
      arguments => {
          url => '/my/other/page',
      },
  )->run;

=head1 DESCRIPTION

Given a URL, this action forces Jifty to perform a redirect to that URL after processing the rest of the request.

=cut

package Jifty::Action::Redirect;
use base qw/Jifty::Action/;

=head1 METHODS

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

    # Return now if the URL is not set
    return 1 unless ($self->argument_value('url'));

    # Return now if the response is already sent (i.e., too late to redirect)
    return 0 unless Jifty->web->response->success;

    # Find the URL to redirect to
    my $page = $self->argument_value('url');

    # Set the next page and force the redirect
    Jifty->web->next_page($page);
    Jifty->web->force_redirect(1);
    return 1;
}

=head1 SEE ALSO

L<Jifty::Action>, L<Jifty::Web/next_page>, L<Jity::Web/force_redirect>

=head1 LICENSE

Jifty is Copyright 2005-2010 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;

