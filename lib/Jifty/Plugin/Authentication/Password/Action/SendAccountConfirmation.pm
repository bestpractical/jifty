use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Authentication::Password::Action::SendAccountConfirmation - send confirmation for an email

=cut

package Jifty::Plugin::Authentication::Password::Action::SendAccountConfirmation;
use base qw/Jifty::Action/;

__PACKAGE__->mk_accessors(qw(user_object));

=head2 arguments

The field for C<ResendConfirmation> is:

=over 4

=item address: the email address

=back

=cut

sub class_arguments {
    return (
        {
            address => {
                label         => _('email address'),
                mandatory     => 1,
                default_value => "",
            },
        }
    );
}

=head2 setup

Create an empty user object to work with

=cut

sub setup {
    my $self = shift;
    my $LoginUser   = Jifty->app_class('Model', 'User');
    my $CurrentUser = Jifty->app_class('CurrentUser');

    $self->user_object(
        $LoginUser->new( current_user => $CurrentUser->superuser ) );
}

=head2 validate_address

Make sure their email address is an unconfirmed user.

=cut

sub validate_address {
    my $self  = shift;
    my $email = shift;

    my $LoginUser   = Jifty->app_class('Model', 'User');
    my $CurrentUser = Jifty->app_class('CurrentUser');

    return $self->validation_error(
        address => _("That doesn't look like an email address.") )
      unless ( $email =~ /\S\@\S/ );

    $self->user_object(
        $LoginUser->new( current_user => $CurrentUser->superuser ) );
    $self->user_object->load_by_cols( email => $email );
    return $self->validation_error(
        address => _("It doesn't look like there's an account by that name.") )
      unless ( $self->user_object->id );

    return $self->validation_error(
        address => _("It looks like you're already confirmed.") )
      if ( $self->user_object->email_confirmed );

    return $self->validation_ok('address');
}

=head2 take_action

Create a new unconfirmed user and send out a confirmation email.

=cut

sub take_action {
    my $self = shift;
    Jifty::Plugin::Authentication::Password::Notification::ConfirmAddress->new( to => $self->user_object )->send;
    return $self->result->message(_("Confirmation resent."));
}

1;
