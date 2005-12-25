package Jifty::Script::Help;
use strict;
use base qw( App::CLI::Command::Help );
use File::Find qw(find);
use Jifty::I18N;

sub help_base {
    return "Jifty::Help";
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

=head1 AUTHOR

Various folks at Best Practical Solutions, LLC.

=cut
