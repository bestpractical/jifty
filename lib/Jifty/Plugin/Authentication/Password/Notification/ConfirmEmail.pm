use warnings;
use strict;

package Jifty::Plugin::Authentication::Password::Notification::ConfirmEmail;
use base qw/Jifty::Notification/;

=head1 NAME

Jifty::Plugin::Authentication::Password::Notification::ConfirmEmail - mail notification to confirm email

=head1 ARGUMENTS

C<to>, a L<$YOURAPP:Model::User> whose address we are confirming.

=cut

=head2 setup

Sets up the fields of the message.

=cut

sub setup {
    my $self = shift;

    my $LoginUser   = Jifty->app_class('Model', 'User');

    unless ( UNIVERSAL::isa($self->to, $LoginUser) ){
        $self->log->error((ref $self) . " called with invalid user argument");
        return;
    } 
   

    my $letme = Jifty::LetMe->new();
    $letme->email($self->to->email);
    $letme->path('confirm_email'); 
    my $confirm_url = $letme->as_url;
    my $appname = Jifty->config->framework('ApplicationName');

    $self->subject( _("Welcome to %1!",$appname ));
    $self->body(_("
You're getting this message because you (or somebody claiming to be you)
wants to use %1. 

We need to make sure that we got your email address right.  Click on the link below to get started:

%2
",$appname,$confirm_url));

}

1;
