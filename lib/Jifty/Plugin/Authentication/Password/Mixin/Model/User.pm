use strict;
use warnings;

package Jifty::Plugin::Authentication::Password::Mixin::Model::User;
use Jifty::DBI::Schema;
use base 'Jifty::DBI::Record::Plugin';

use Digest::MD5 qw'';

our @EXPORT = qw(password_is hashed_password_is regenerate_auth_token has_alternative_auth);

=head1 NAME

Jifty::Plugin::Authentication::Password::Mixin::Model::User - password plugin user mixin model

=head1 SYNOPSIS

  package MyApp::Model::User;
  use Jifty::DBI::Schema;
  use MyApp::Record schema {
      # custom column definitions
  };

  use Jifty::Plugin::User::Mixin::Model::User; # name, email, email_confirmed
  use Jifty::Plugin::Authentication::Password::Mixin::Model::User;
  # ^^ password, auth_token

=head1 DESCRIPTION

This mixin model is added to the application's account model for use with the password authentication plugin. This mixin should be used in combination with L<Jifty::Plugin::User::Mixin::Model::User>.

=head1 SCHEMA

This mixin adds the following columns to the model schema:

=head2 auth_token

This is a unique identifier used when confirming a user's email account and recovering a lost password.

=head2 password

This is the user's password. It will be stored in the database after being processed through L<Digest::MD5>, so the password cannot be directly recovered from the database.

=cut

use Jifty::Plugin::Authentication::Password::Record schema {


column auth_token =>
  render_as 'unrendered',
  type is 'varchar(255)',
  max_length is 255,
  default is '',
  label is _('Authentication token');
    


column password =>
  is unreadable,
  label is _('Password'),
  type is 'varchar(64)',
  max_length is 64,
  hints is _('Your password should be at least six characters'),
  render_as 'password',
  filters are 'Jifty::DBI::Filter::SaltHash';


};

=head1 METHODS

=head2 register_triggers

Adds the triggers to the model this mixin is added to.

=cut

sub register_triggers {
    my $self = shift;
    $self->add_trigger(name => 'after_create', callback => \&after_create);
    $self->add_trigger(name => 'after_set_password', callback => \&after_set_password);
    $self->add_trigger(name => 'validate_password', callback => \&validate_password, abortable =>1);
}


=head2 password_is PASSWORD

Checks if the user's password matches the provided I<PASSWORD>.

=cut

sub password_is {
    my $self = shift;
    my $pass = shift;

    return undef unless $self->__value('password');
    my ($hash, $salt) = @{$self->__value('password')};

    return 1 if ( $hash eq Digest::MD5::md5_hex($pass . $salt) );
    return undef;

}

=head2 hashed_password_is HASH TOKEN

Check if the given I<HASH> is the result of hashing our (already
salted and hashed) password with I<TOKEN>.

This can be used in cases where the pre-hashed password is sent during login as an additional security precaution (such as could be done via Javascript).

=cut

sub hashed_password_is {
    my $self = shift;
    my $hash = shift;
    my $token = shift;

    my $password = $self->__value('password');
    return $password && Digest::MD5::md5_hex("$token " . $password->[0]) eq $hash;
}


=head2 validate_password

Makes sure that the password is six characters long or longer, unless
we have alternative means to authenticate.

=cut

sub validate_password {
    my $self      = shift;
    my $new_value = shift;

    return 1 if $self->has_alternative_auth();

    return ( 0, _('Passwords need to be at least six characters long') )
        if length($new_value) < 6;

    return 1;
}

=head2 after_create

This trigger is added to the account model. It automatically sends a notification email to the user for password confirmation.

See L<Jifty::Plugin::Authentication::Password::Notification::ConfirmEmail>.

=cut


sub after_create {
    my $self = shift;
    # We get a reference to the return value of insert
    my $value = shift; return unless $$value; $self->load($$value);
    $self->regenerate_auth_token;
    if ( $self->id and $self->email and not $self->email_confirmed ) {
        Jifty->app_class('Notification','ConfirmEmail')->new( to => $self )->send;
    }
}

=head2 has_alternative_auth

If your model supports other means of authentication, you should have
this method return true, so the C<password> field can optionally be
null and authentication with password is disabled in that case.

=cut

sub has_alternative_auth { }

=head2 after_set_password

Regenerate authentication tokens on password change

=cut

sub after_set_password {
    my $self = shift;
    $self->regenerate_auth_token;
}

=head2 regenerate_auth_token

Generate a new auth_token for this user. This will invalidate any
existing feed URLs.

=cut

sub regenerate_auth_token {
    my $self = shift;
    my $auth_token = '';

    $auth_token .= unpack('H2', chr(int rand(256))) for (1..16);

    $self->__set(column => 'auth_token', value => $auth_token);
}

=head1 SEE ALSO

L<Jifty::Plugin::Authentication::Password>, L<Jifty::Plugin::User::Mixin::Model>

=head1 LICENSE

Jifty is Copyright 2005-2007 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;

