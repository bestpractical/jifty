use strict;
use warnings;

=head1 NAME

Jifty::Plugin::OpenID::Action::CreateOpenIDUser - create 0penId user

=cut

package Jifty::Plugin::OpenID::Action::CreateOpenIDUser;
use base qw/Jifty::Action::Record/;

=head2 record_class 

Returns the record class for this action

=cut

sub record_class {
    Jifty->app_class("Model", "User")
}


=head2 arguments

The fields for C<CreateOpenIDUser> are:

=over 4

=item name: a nickname

=back

=cut

sub arguments {
    my $self = shift;
    my $args = $self->record_class->new->as_create_action->arguments;
    delete $args->{openid};
    return $args;
}

=head2 take_action

=cut

sub take_action {
    my $self = shift;

    my $openid = Jifty->web->session->get('openid');

    if ( not $openid ) {
        # Should never get here unless someone's trying weird things
        $self->result->error("Invalid verification result: '$openid'");
        return;
    }

    my $user = $self->record_class->new(current_user => Jifty->app_class("CurrentUser")->superuser );

    $user->load_by_cols( openid => $openid );

    if ( $user->id ) {
        $self->result->error( "That OpenID already has an account.  Something's gone wrong." );
        return;
    }

    $user->create( openid => $openid, %{$self->argument_values} );

    if ( not $user->id ) {
        $self->result->error( "Something bad happened and we couldn't log you in.  Please try again later." );
        return;
    }

    my $current_user = Jifty->app_class("CurrentUser")->new( openid => $openid );

    # Actually do the signin thing.
    Jifty->web->current_user($current_user);
    Jifty->web->session->expires( undef );
    Jifty->web->session->set_cookie;

    $self->report_success if not $self->result->failure;
    Jifty->web->session->remove('openid');

    return 1;
}

=head2 report_success

=cut

sub report_success {
    my $self = shift;
    # Your success message here
    $self->result->message( _("Welcome, ") . Jifty->web->current_user->username . "." );
}

1;

