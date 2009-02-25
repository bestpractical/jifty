use strict;
use warnings;

package Jifty::Plugin::REPL;
use base qw/Jifty::Plugin/;

=head1 NAME

Jifty::Plugin::REPL - Provide a read-eval-print loop for Jifty

=head1 SYNOPSIS

In your config.yml or equivilent:

  Plugins:
   - REPL: {}

From the command line:

  jifty repl

=head1 DESCRIPTION

See L<Jifty::Plugin::REPL::Script::Repl> for details on the REPL
environment.

=cut

1;
