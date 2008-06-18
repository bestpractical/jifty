
use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Feedback::Action::SendFeedback - Send feedback by mail

=cut

package Jifty::Plugin::Feedback::Action::SendFeedback;
use base qw/Jifty::Action/;
use Jifty::Notification;

=head2 arguments

The fields for C<SendFeedback> are:

=over 4

=item content: a big box where the user can type in what eits them


=back

=cut

sub arguments {
        {
            content => {
                    label   => '',
                    render_as => 'Textarea',
                    rows => 5,
                    cols => 60,
                    sticky => 0
            },
        }

}

=head2 take_action

Send a mail to the feedback recipient describing the issue.

=cut

sub take_action {
    my $self = shift;
    return 1 unless ( $self->argument_value('content') );

    my ($plugin) = Jifty->find_plugin('Jifty::Plugin::Feedback');
    my $debug_info = $self->build_debugging_info();

    my $msg = $self->argument_value('content') . "\n\n" . $debug_info;
    my $subject = substr( $self->argument_value('content'), 0, 60 );
    $subject =~ s/\n/ /g;

    # Fall back to normal email
    my $mail = Jifty::Notification->new;
    $mail->body($msg);

    if (    Jifty->web->current_user->id
         && Jifty->web->current_user->user_object->can('email') ) {

         my $user = Jifty->web->current_user->user_object;
         my $CurrentUser = Jifty->app_class('CurrentUser');
         $user->current_user( $CurrentUser->superuser );
         $mail->from( $user->email() || $plugin->from );
    }
    else {
        $mail->from( $plugin->from );
    }

    $mail->recipients( $plugin->to );
    $mail->subject( "["
            . Jifty->config->framework('ApplicationName')
            . " feedback] "
            . $subject );
    $mail->send_one_message;

    $self->result->message(qq[Thanks for the feedback. We appreciate it!]);
    return 1;
}

=head2 build_debugging_info

Strings together the current environment to attach to outgoing
email. Returns it as a scalar.

=cut

sub build_debugging_info {
    my $self = shift;
    my $message = "-- \nPrivate debugging information:\n";
    $message   .= " $_: $ENV{$_}\n"
      for sort grep {/^(HTTP|REMOTE|REQUEST)_/} keys %ENV;

    return $message;
}

1;
