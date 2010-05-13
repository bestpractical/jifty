use warnings;
use strict;

=head1 NAME

Jifty::Action::AboutMe - Give information about the current user

=head1 DESCRIPTION

This action is used for external consumers of Jifty's various APIs to get
information about the current user.

=cut

package Jifty::Action::AboutMe;
use base qw/Jifty::Action/;

=head2 take_action

Does nothing except set the results to the L<Jifty::CurrentUser> object.
=cut

sub take_action {
    my $self = shift;

    $self->result->content(current_user => $self->current_user);
    $self->report_success;

    return 1;
}

=head1 SEE ALSO

L<Jifty::Action>, L<Jifty::CurrentUser>

=head1 LICENSE

Jifty is Copyright 2005-2010 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;

