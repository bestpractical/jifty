use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Authentication::Password::Action::SendPasswordReminder - send a link to reset a password

=cut

package Jifty::Plugin::Authentication::Password::Action::SendPasswordReminder;
use base qw/Jifty::Action/;


__PACKAGE__->mk_accessors(qw/user_object/);

=head2 arguments

The field for C<SendLostPasswordReminder> is:

=over 4

=item address: the email address

=back

=cut

sub arguments {
    return (
        {
            address => {
                label     => _('Email'),
                mandatory => 1,
            },
        }
    );

}

=head2 setup

Create an empty user object to work with

=cut

sub setup {
    my $self = shift;
    my $LoginUser   = Jifty->app_class('Model','User');
        my $CurrentUser = Jifty->app_class('CurrentUser');



    # Make a blank user object
    $self->user_object(
        $LoginUser->new( current_user => $CurrentUser->superuser ) );
}

=head2 validate_address

Make sure there's actually an account by that name.

=cut

sub validate_address {
    my $self  = shift;
    my $email = shift;
    my $LoginUser   = Jifty->app_class('Model','User');
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

    return $self->validation_ok('address');
}

=head2 take_action

Send out a Reminder email giving a link to a password-reset form.

=cut

sub take_action {
    my $self = shift;
    Jifty->app_class('Notification','ConfirmLostPassword')->new(
        to => $self->user_object )->send;
    return $self->result->message(
        _("A link to reset your password has been sent to your email account."));
}

1;

