use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Authentication::Password::Action::ResendConfirmation - resend confirmation for new mail or password

=cut

package Jifty::Plugin::Authentication::Password::Action::ResendConfirmation;
use base qw/Jifty::Action/;

__PACKAGE__->mk_accessors(qw(user_object));


=head2 arguments

The field for C<ResendConfirmation> is:

=over 4

=item email: the email email

=back

=cut

sub class_arguments {
    return (
        {
            email => {
                label     => 'Email address',
                mandatory => 1,
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
    
    # Make a blank user object
    $self->user_object(Jifty->app_class('Model','User')->new(current_user => Jifty->app_class('CurrentUser')->superuser));
}

=head2 validate_email

Make sure their email email is an unconfirmed user.

=cut

sub validate_email {
    my $self  = shift;
    my $email = shift;

    unless ( $email =~ /\S\@\S/ ) {
        return $self->validation_error(email => "Are you sure that's an email email?" );
    }

    $self->user_object(Jifty->app_class('Model','User')->new(current_user => Jifty->app_class('CurrentUser')->superuser));
    $self->user_object->load_by_cols( email => $email );
    unless ($self->user_object->id) {
      return $self->validation_error(email => "It doesn't look like there's an account by that name.");
    }

    if ($self->user_object->email_confirmed) {
      return $self->validation_error(email => "It looks like you're already confirmed.");

    } 

    return $self->validation_ok('email');
}

=head2 take_action

Create a new unconfirmed user and send out a confirmation email.

=cut

sub take_action {
    my $self = shift;
    my $user = $self->user_object();

    Jifty->app_class('Notification','ConfirmEmail')->new( to => $user )->send;
    
    $self->result->message("We've re-sent your confirmation.");

    return 1;
}

1;
