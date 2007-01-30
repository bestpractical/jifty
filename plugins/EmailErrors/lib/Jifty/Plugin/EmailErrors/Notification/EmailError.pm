use warnings;
use strict;

package Jifty::Plugin::EmailErrors::Notification::EmailError;
use base qw/Jifty::Notification/;

sub setup {
    my $self = shift;
    
    my $cont = Jifty->web->request->continuation;
    my $e    = $cont->response->error;
    my $msg  = $e->message;
    $msg =~ s/, <\S+> (line|chunk) \d+\././;

    my $info  = $e->analyze_error;
    my $file  = $info->{file};
    my @lines = @{ $info->{lines} };
    my @stack = @{ $info->{frames} };

    $self->to( $Jifty::Plugin::EmailErrors::Notification::EmailError::TO );
    $self->from( $Jifty::Plugin::EmailErrors::Notification::EmailError::FROM );
    $self->subject( $Jifty::Plugin::EmailErrors::Notification::EmailError::SUBJECT );

    my $body;
    $body = "Error in $file, line @lines\n$msg\n";
    for my $frame (@stack) {
        next if $frame->filename =~ m{/HTML/Mason/};
        $body .= "  ".$frame->filename.", line ".$frame->line."\n";
    }

    $body .= "\n\n";
    $body .= $self->get_environment;
    
    $self->body($body);
}

sub get_environment {
    my $self = shift;
    my $message = '';

    $message = "Environment:\n\n";
    $message   .= " $_: $ENV{$_}\n"
      for sort grep {/^(HTTP|REMOTE|REQUEST)_/} keys %ENV;

    return $message;
}

1;
