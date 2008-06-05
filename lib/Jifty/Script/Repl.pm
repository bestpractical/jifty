use strict;
use warnings;

package Jifty::Script::Repl;
use base qw/Jifty::Script/;
use Devel::REPL::Script;

=head1 NAME

Jifty::Script::Repl - A REPL for your Jifty application

=head1 SYNOPSIS

    jifty repl
    jifty repl --help
    jifty repl --man

=head1 OPTIONS

This script has no specific options now except help.
Maybe it will have some command lines options in the future.

=over 8

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

This gives you a L<Devel::REPL> for your Jifty application. L<Devel::REPL> is a
powerful and extensible read-eval-print-loop (basically a line-by-line
interpreter). This command is similar to, but more useful than,
C<jifty console>. C<jifty console> is literally read-eval-print-loop but without
any of the nice plugins (such as colors, auto-dump output, interrupt
long-running commands, autorefresh code each line, etc).

=head1 METHODS

=head2 run()

Creates a L<Devel::REPL> object and runs it.

=cut

sub run {
    my $self = shift;
    $self->print_help();
    Jifty->new();
    Devel::REPL::Script->new->run();
}

1;

=head1 AUTHOR

Shawn M Moore C<<sartak@bestpractical.com>>

=cut
