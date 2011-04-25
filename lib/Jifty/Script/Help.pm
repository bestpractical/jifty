package Jifty::Script::Help;
use strict;
use base qw/ App::CLI::Command::Help Jifty::Script /;
use File::Find qw/find/;

sub help_base {
    return "Jifty::Manual";
}

1;

__DATA__

=head1 NAME

Jifty::Script::Help - Show help

=head1 SYNOPSIS

 help COMMAND

=head1 OPTIONS

Optionally help can pipe through a pager, to make it easier to
read the output if it is too long. For using this feature, please
set environment variable PAGER to some pager program.
For example:

    # bash, zsh users
    export PAGER='/usr/bin/less'

    # tcsh users
    setenv PAGER '/usr/bin/less'

=head2 help_base

Jifty's help system also looks in L<Jifty::Manual> and the
subdirectories for any help commands that it can't find help for.

=head1 AUTHOR

Various folks at Best Practical Solutions, LLC.

=cut
