use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Users::Identity::File::Action::Login

=cut

package Jifty::Plugin::Users::Identity::File::Action::Login;
use base qw/Jifty::Action Jifty::Plugin::Users Jifty::Plugin::Users::Identity::File/;


=head2 arguments

Return the ticket form field

=cut

sub arguments {
    return (
        {
            login => {
                label          => 'login',
                mandatory      => 1,
                ajax_validates => 1,
            },
            password => {
                label          => 'password',
                mandatory      => 1,
            },

        }
    );

}

=head2 validate_ticket ST

for ajax_validates
Makes sure that the ticket submitted is legal.


=cut

sub validate_login {
    my $self  = shift;
    my $login = shift;

    unless ( $login && $login !~ /^[A-Za-z0-9-]+$/ ) {
        return $self->validation_error(
            ticket => _("That doesn't look like a valid ticket.") );
    }


    return $self->validation_ok('login');
}


=head2 take_action

Actually check the user's password. If it's right, log them in.
Otherwise, throw an error.


=cut

sub take_action {
    my $self = shift;
    my $login = $self->argument_value('login');
    my $password = $self->argument_value('password');

    my $LoginUser = $self->UserClass();
    my $CurrentUser = $self->CurrentUserClass();
    my $u = $LoginUser->new( current_user => $CurrentUser->superuser );

    $u->load_by_cols( display_name => $login, realm => 'file' );
    my $id = $u->id;
    if (!$id) { 
   	($id) = $u->create(display_name => $login, realm => 'file' ); 
	}
    Jifty->log->debug("Login user id: $id"); 

    # Actually do the signin thing.
     Jifty->web->current_user( $CurrentUser->new( id => $u->id ) );

    return 1;
}

1;
