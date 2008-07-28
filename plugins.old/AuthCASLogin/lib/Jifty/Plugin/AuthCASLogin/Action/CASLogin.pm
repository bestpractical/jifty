use warnings;
use strict;

=head1 NAME

Jifty::Plugin::AuthCASLogin::Action::CASLogin

=cut

package Jifty::Plugin::AuthCASLogin::Action::CASLogin;
use base qw/Jifty::Action Jifty::Plugin::Login Jifty::Plugin::AuthCASLogin/;
#use AuthCAS;


=head2 arguments

Return the ticket form field

=cut

sub arguments {
    return (
        {
            ticket => {
                label          => 'cas ticket',
           #     mandatory      => 1,
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

    unless ( $ticket && $ticket !~ /^[A-Za-z0-9-]+$/ ) {
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

    my $service_url = ($ENV{SERVER_PORT} == 443)?'https://':'http://'.
    	$ENV{HTTP_HOST}.'/caslogin';

    if (! $ticket) {
        my $login_url = $self->CAS->getServerLoginURL($service_url);
        Jifty->web->_redirect($login_url);
        return 1;
      }
      
    my $username = $self->CAS->validateST($service_url,$ticket);
    my $error = &AuthCAS::get_errors();
    if ($error) {
      Jifty->log->info("CAS error: $ticket $username : $error");
      return;
    }
      
    my $LoginUser = $self->LoginUserClass();
    my $CurrentUser = $self->CurrentUserClass();
    my $u = $LoginUser->new( current_user => $CurrentUser->superuser );

    $u->load_by_cols( email => $username.'@CAS.user');
    my $id = $u->id;
    if (!$id) { 
   	($id) = $u->create(name => $username, email => $username.'@CAS.user'); 
	}
    Jifty->log->debug("Login user id: $id"); 

    # Actually do the signin thing.
     Jifty->web->current_user( $CurrentUser->new( id => $u->id ) );

    return 1;
}

1;
