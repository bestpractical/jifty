use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Authentication::Ldap::Action::LDAPLogin;

=cut

package Jifty::Plugin::Authentication::Ldap::Action::LDAPLogin;
use base qw/Jifty::Action/;


=head1 ARGUMENTS

Return the login form field

=cut

use Jifty::Param::Schema;
use Jifty::Action schema {
    param ldap_id => 
        label is _('Login'),
        is mandatory;
#        is ajax_validates;
    param password =>
        type is 'password',
        label is _('Password'),
        is mandatory;
};

=head2 validate_name NAME

For ajax_validates.
Makes sure that the name submitted is a legal login.


=cut

sub validate_ldap_id {
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
    my $username = $self->argument_value('ldap_id');
    my ($plugin)  = Jifty->find_plugin('Jifty::Plugin::Authentication::Ldap');
    my $dn = $plugin->uid().'='.$username.','.
        $plugin->base();

    Jifty->log->debug( "dn = $dn" );

    # Bind on ldap
    my $msg = $plugin->LDAP()->bind($dn ,'password' =>$self->argument_value('password'));


    if ($msg->code) {
        $self->result->error(
     _('You may have mistyped your login or password. Give it another shot?')
        );
        Jifty->log->error( "LDAP bind $dn " . $msg->error . "" );
        return;
    }

    # Load up the user
    my $infos =  $plugin->get_infos($username);
    my $name = $infos->{name};
    my $email = $infos->{email};
 
    my $current_user = Jifty->app_class('CurrentUser');
    my $user = ($email) 
        ? $current_user->new( email => $email)    # load by email to mix authentication
        : $current_user->new( ldap_id => $username );  # else load by ldap_id


    # Autocreate the user if necessary
    if ( not $user->id ) {
        my $action = Jifty->web->new_action(
            class           => 'CreateUser',
            current_user    => $current_user->superuser,
            arguments       => {
                ldap_id => $username
            }
        );
        $action->run;

        if ( not $action->result->success ) {
            # Should this be less "friendly"?
            $self->result->error(_("Sorry, something weird happened (we couldn't create a user for you).  Try again later."));
            return;
        }

        $user = $current_user->new( ldap_id => $username );
    }

    my $u = $user->user_object;

    # Update, just in case
    $u->__set( column => 'name', value => $name );
    $u->__set( column => 'email', value => $email );


    # Login!
    Jifty->web->current_user( $user );
    Jifty->web->session->set_cookie;

    # Success!
    $self->report_success;

    return 1;
};

=head2 report_success

=cut

sub report_success {
    my $self = shift;
    $self->result->message(_("Hi %1!", Jifty->web->current_user->user_object->name ));
};


1;
