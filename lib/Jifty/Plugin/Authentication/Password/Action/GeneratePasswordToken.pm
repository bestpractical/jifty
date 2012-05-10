use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Authentication::PasswordAction::GeneratePasswordToken - generate password token

=cut

package Jifty::Plugin::Authentication::Password::Action::GeneratePasswordToken;
use base qw/Jifty::Action/;

__PACKAGE__->mk_accessors( 'login_by' );

=head1 METHODS

=head2 new

Looks up what L<Jifty::Plugin::Authentication::Password> is configured
to login via, username or email address, to know what form element to
expect.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my $plugin =
        Jifty->find_plugin('Jifty::Plugin::Authentication::Password');
    $self->login_by( $plugin->{login_by} || 'email' );
    return $self;
}

=head2 arguments

We need the email of the user we're fetching a token for, so we can
return the salt.

=cut

sub arguments {
    my $self = shift;
    return( { $self->login_by => { mandatory => 1 } });

}


=head2 take_action

Generate a token and throw it back to the browser.  Also, return the
user's password salt in $self->result->content.

=cut

sub take_action {
    my $self = shift;

    my $user = $self->load_user( $self->argument_value( $self->login_by ) );
    my $password = $user->_value('password');

    my $token = time();
    $self->result->content(token => $token);
    $self->result->content(salt  => ($password ? $password->[1] : ""));
    Jifty->web->session->set(login_token => $token);
}

=head2 load_user

Load up and return a YourApp::User object for the user trying to log in

=cut

sub load_user {
    my $self = shift;
    my $value = shift;
    my $user = Jifty->app_class('Model', 'User')->new(
        current_user => Jifty->app_class('CurrentUser')->superuser
    );

    # normally we use name as column name instead of usernmae
    my $column = $self->login_by eq 'username' ? 'name' : $self->login_by;
    $user->load_by_cols( $column => $value );
    return $user;

}

1;
