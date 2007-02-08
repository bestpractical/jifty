package Jifty::Script;
use App::CLI;
use base qw/App::CLI App::CLI::Command/;

=head2 prepare

C<prepare> figures out which command to run. If the user wants
C<--help> give them help.

In the normal case, let App::CLI figure out the commandline.
If they have no command on the commandline, but a JIFTY_COMMAND
environment variable, try that.  Otherwise, if the GATEWAY_INTERFACE
environment variable is set, assume we are running under CGI with the
C<fastcgi> command.  If all fails, shows the help.

=cut

sub prepare {
    my $self = shift;
    if ($ARGV[0] =~ /--?h(elp?)/i) {
        shift @ARGV; #discard the --help
        unshift @ARGV, 'help';
    }
    elsif (!@ARGV) {
        if ( my $cmd = $ENV{'JIFTY_COMMAND'} ) {
            unshift @ARGV, $cmd;
        }
        elsif ( $ENV{GATEWAY_INTERFACE} ) {
            unshift @ARGV, 'fastcgi';
        }
        else {
            unshift @ARGV, 'help';
        }
    }
    return $self->SUPER::prepare(@_);
}

=head2 alias

The alias table lets users type C<fastcgi> in place of C<FastCGI>.

=cut

sub alias {
    return (
            fastcgi => "FastCGI",
           )
}




1;
