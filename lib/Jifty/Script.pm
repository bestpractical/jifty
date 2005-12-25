package Jifty::Script;
use base qw/App::CLI App::CLI::Command/;
use Jifty::I18N;
use UNIVERSAL::require;

=head2 prepare

C<prepare> figures out which command to run. If the user wants
C<--help> give them help. If they have no command on the commandline,
but a JIFTY_COMMAND environment variable, try that. If they have
neither, show em help. Otherwise, lett App::CLI figure it out.

=cut

sub prepare {
    my $self = shift;
    if ($ARGV[0] =~ /--?h(elp?)/i) {
        shift @ARGV; #discard the --help
        unshift @ARGV, 'help';
    } elsif (!$ARGV[0] and $ENV{'JIFTY_COMMAND'}) {
        my $cmd = $ENV{'JIFTY_COMMAND'};
        unshift @ARGV, $cmd;
    } elsif (! @ARGV) {
        unshift @ARGV, 'help';
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
