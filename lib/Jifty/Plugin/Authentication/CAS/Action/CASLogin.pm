use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Authentication::CAS::Action::CASLogin

=cut

package Jifty::Plugin::Authentication::CAS::Action::CASLogin;
use base qw/Jifty::Action/;


=head2 arguments

Return the ticket form field

=cut

sub arguments {
    return (
        {
            ticket => {
                label          => 'cas ticket',
                ajax_validates => 1,
            },

        }
    );

}

=head2 validate_ticket ST

for ajax_validates
Makes sure that the ticket submitted is legal.


=cut

sub validate_ticket {
    my $self  = shift;
    my $ticket = shift;

    if ( $ticket && $ticket !~ /^[A-Za-z0-9-]+$/ ) {
        return $self->validation_error(
            ticket => _("That doesn't look like a valid ticket.") );
    }


    return $self->validation_ok('ticket');
}


=head2 take_action

Actually check the user's password. If it's right, log them in.
Otherwise, throw an error.


=cut

sub take_action {
    my $self = shift;
    my $ticket = $self->argument_value('ticket');

    my ($plugin)  = Jifty->find_plugin('Jifty::Plugin::Authentication::CAS');

#    my $service_url = ($ENV{SERVER_PORT} == 443)?'https://':'http://'.
#    	$ENV{HTTP_HOST}.'/caslogin';
    
    my $service_url = Jifty->web->url.'/caslogin';

    if (! $ticket) {
        my $login_url = $plugin->CAS->login_url( $service_url );
        Jifty->web->_redirect($login_url);
        return 1;
      }

    my $r = $plugin->CAS->service_validate($service_url,$ticket);
    my $username;
    if ($r->is_success) {
        $username = $r->user();
    }
    else {
      Jifty->log->info("CAS error: $ticket $username");
      return;
    };
     
    # Load up the user
    my $current_user = Jifty->app_class('CurrentUser');
    my $user = $current_user->new( cas_id => $username );

    # Autocreate the user if necessary
    if ( not $user->id ) {
        my $action = Jifty->web->new_action(
            class           => 'CreateUser',
            current_user    => $current_user->superuser,
            arguments       => {
                cas_id => $username
            }
        );
        $action->run;

        if ( not $action->result->success ) {
            # Should this be less "friendly"?
            $self->result->error(_("Sorry, something weird happened (we couldn't create a user for you).  Try again later."));
            return;
        }

        $user = $current_user->new( cas_id => $username );
    }

    my $u = $user->user_object;

    my ($name,$email);
    #TODO add a ldap conf to find name and email
    $email = $username.'@'.$plugin->domain() if ($plugin->domain());
    $u->__set( column => 'name', value => $username ) if (!$u->name);

    # Update, just in case
    $u->__set( column => 'name', value => $name ) if ($name);
    $u->__set( column => 'email', value => $email ) if ($email);
 
    # Actually do the signin thing.
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
