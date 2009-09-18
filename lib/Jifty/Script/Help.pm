package Jifty::Script::Help;
use strict;
use base qw( App::CLI::Command::Help Jifty::Script );
use File::Find qw(find);

sub run {
    my $self   = shift;
    my @topics = @_;

    push @topics, 'commands' unless (@topics);

    foreach my $topic (@topics) {
        if ( $topic eq 'commands' ) {
            $self->brief_usage($_) for $self->app->files;
        }
        elsif ( grep { $topic eq $_ } @Jifty::Script::CORE_CMDS ) {
            # to find usage of a CMD, App::CLI will require the CMD.pm first
            # that's too heavy for us because some CMD.pm `use Jifty', 
            # which `use Jifty::Everything'!
            my $file = $INC{'Jifty/Script/Help.pm'};
            $file =~ s/Help(?=\.pm$)/ucfirst $topic/e;

            open my $fh, '<:utf8', $file or die $!;
            require Pod::Simple::Text;
            my $parser = Pod::Simple::Text->new;
            my $buf;
            $parser->output_string( \$buf );
            $parser->parse_file($fh);
            print $self->loc_text($buf);
        }
        else {
            $self->SUPER::run($topic);
        }
    }
}

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
