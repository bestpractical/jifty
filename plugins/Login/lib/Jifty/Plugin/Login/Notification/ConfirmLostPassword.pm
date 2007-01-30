use warnings;
use strict;

package Jifty::Plugin::Login::Notification::ConfirmLostPassword;
use base qw/Jifty::Notification Jifty::Plugin::Login/;

=head1 NAME

Jifty::Plugin::Login::Notification::ConfirmLostPassword

=head1 ARGUMENTS

C<to>, a L<Jifty::Plugin::Login::Model::User> whose address we are confirming.

=cut

=head2 setup

Sets up the fields of the message.

=cut

sub setup {
    my $self = shift;

    unless ( UNIVERSAL::isa($self->to, $self->LoginUserClass) ){
	$self->log->error((ref $self) . " called with invalid user argument");
	return;
    }

    my $letme = Jifty::LetMe->new();
    $letme->email($self->to->email);
    $letme->path('reset_lost_password');
    my $confirm_url = $letme->as_url;
    my $appname = Jifty->config->framework('ApplicationName');

    $self->subject( _("Message from ")."$appname!" );
    $self->from( Jifty->config->framework('AdminEmail') );

    $self->body(_("
You're getting this message because you (or somebody claiming to be you)
request to reset your password for %1.

If you don't want to reset your password just ignore this message.

To reset your password, click on the link below:

%2
",$appname,$confirm_url));

}

1;

