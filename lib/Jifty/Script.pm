package Jifty::Script;
use App::CLI;
use base qw/App::CLI App::CLI::Command Jifty::Object/;

use Jifty::Everything;
Jifty::Everything->plugin_commands;
use Pod::Usage;

=head1 NAME

Jifty::Script - Base class for all bin/jifty commands

=head1 METHODS

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
    if ($ARGV[0] =~ /--?h(elp)?/i) {
        $ARGV[0] = 'help';
    }
    elsif ( $ARGV[0] =~ /^(-v|--version|version)$/ ) {
        print "This is Jifty, version $Jifty::VERSION\n";
        exit 0;
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

=head2 options

=cut

sub options {
    return (
     'h|help|?' => 'help',
     'man'      => 'man',
    );
}

=head2 alias

The alias table lets users type C<fastcgi> in place of C<FastCGI>.

=cut

sub alias {
    return (
            fastcgi => "FastCGI",
           )
}

=head2 print_help

Prints out help for the package using pod2usage.

If the user specified --help, prints a brief usage message

If the user specified --man, prints out a manpage

=cut

sub print_help {
    my $self = shift;
    my $msg = shift;

    $self->{'help'} = 1
        if $msg && !( $self->{'help'} || $self->{'man'} );

    my %opts = (
        -exitval => $msg? 1: 0,
        -input   => $self->filename,
        -verbose => 99,
        $msg? (-message => $msg): (),
    );
    # Option handling
    pod2usage(
        %opts,
        -sections => 'NAME|SYNOPSIS',
    ) if $self->{help};
    pod2usage(
        %opts,
        -sections => '!METHODS',
    ) if $self->{man};
}

1;
