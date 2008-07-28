use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Login::Action::Logout

=cut

package Jifty::Plugin::Login::Action::Logout;
use base qw/Jifty::Action/;

=head2 arguments

Return the email and password form fields

=cut

sub arguments {
    return ( {} );
}

=head2 take_action

Nuke the current user object

=cut

sub take_action {
    my $self = shift;
    Jifty->web->current_user(undef);
    $self->result->message( _("Ok, you're logged out now. Have a good day.") );
    return 1;
}

1;
