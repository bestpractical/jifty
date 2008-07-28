use warnings;
use strict;

=head1 NAME

Jifty::Plugin::AuthLDAPLogin::Action::LDAPLogin

=cut

package Jifty::Plugin::AuthLDAPLogin::Action::LDAPLogin;
use base qw/Jifty::Action Jifty::Plugin::Login Jifty::Plugin::AuthLDAPLogin/;


=head2 arguments

Return the login form field

=cut

sub arguments {
    return (
        {
            name => {
                label          => _('Login'),
                mandatory      => 1,
                ajax_validates => 1,
            },

            password => {
                type      => 'password',
                label     => _('Password'),
                mandatory => 1
            },

        }
    );

}

=head2 validate_name NAME

For ajax_validates.
Makes sure that the name submitted is a legal login.


=cut

sub validate_name {
    my $self  = shift;
    my $name = shift;

    unless ( $name =~ /^[A-Za-z0-9-]+$/ ) {
        return $self->validation_error(
            name => _("That doesn't look like a valid login.") );
    }


    return $self->validation_ok('name');
}


=head2 take_action

Bind on ldap to check the user's password. If it's right, log them in.
Otherwise, throw an error.


=cut

sub take_action {
    my $self = shift;
    my $username = $self->argument_value('name');
    my $dn = $self->uid().'='.$username.','.
        $self->base();

    # Bind on ldap
    my $msg = $self->LDAP()->bind($dn ,'password' =>$self->argument_value('password'));
    
    unless (not $msg->code) {
        $self->result->error(
     _('You may have mistyped your login or password. Give it another shot?')
        );
        return;
    }

    my $LDAPUser = $self->LoginUserClass();
    my $CurrentUser = $self->CurrentUserClass();
    my $u = $LDAPUser->new( current_user => $CurrentUser->superuser );

    # Distinct id is login@LDAP.user
    # Add user to User Login model
    $u->load_by_cols( email => $username.'@LDAP.user');
    my $id = $u->id;
    if (!$id) {
        ($id) = $u->create(name => $username, email => $username.'@LDAP.user');
    }

    Jifty->log->debug("Login user id: $id"); 

    # Actually do the signin thing.
     Jifty->web->current_user( $CurrentUser->new( id => $u->id ) );

    return 1;
}

1;
