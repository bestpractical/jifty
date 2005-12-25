package Jifty::Script::Help;
use strict;
use base qw( Jifty::Script::Command );
use File::Find qw(find);
use Jifty::I18N;

sub parse_arg { shift; @_ ? @_ : 'index'; }

# Note: lock is not called for help, as it's invoked differently from
# other commands.

sub run {
    my $self = shift;
    my @topics = @_;

    push @topics, 'commands' unless (@topics);

    foreach my $topic (@topics) {
        if ($topic eq 'commands') {
            my @cmd;
            my $dir = $INC{'Jifty/Script.pm'};
            $dir =~ s/\.pm$//;
            print loc("Available commands:\n");
            find (
                sub { push @cmd, $File::Find::name if m/\.pm$/ }, $dir,
            );
            $self->brief_usage ($_) for sort @cmd;
        }
        elsif (my $cmd = eval { Jifty::Script->get_cmd ($topic) }) {
            $cmd->usage(1);
        }
        elsif (my $file = $self->_find_topic($topic)) {
            open my $fh, '<:utf8', $file or die $!;
            my $parser = Pod::Simple::Text->new;
            my $buf;
            $parser->output_string(\$buf);
            $parser->parse_file($fh);

            $buf =~ s/^NAME\s+(.*?)::Help::\S+ - (.+)\s+DESCRIPTION/    $1:/;

        }
        else {
            die loc("Cannot find help topic '%1'.\n", $topic);
        }
    }
    return;
}

my ($inc, @prefix);
sub _find_topic {
    my ($self, $topic) = @_;

    if (!$inc) {
        my $pkg = __PACKAGE__;
        $pkg =~ s{::}{/};
        $inc = substr( __FILE__, 0, -length("$pkg.pm") );

        @prefix = (loc("Jifty::Help"));
        $prefix[0] =~ s{::}{/}g;
        push @prefix, 'Jifty/Help' if $prefix[0] ne 'Jifty/Help';
    }

    foreach my $dir ($inc, @INC) {
        foreach my $prefix (@prefix) {
            foreach my $basename (ucfirst(lc($topic)), uc($topic)) {
                foreach my $ext ('pod', 'pm') {
                    my $file = "$dir/$prefix/$basename.$ext";
                    return $file if -f $file;
                }
            }
        }
    }

    return;
}


1;

__DATA__

=head1 NAME

Jifty::Script::Help - Show help

=head1 SYNOPSIS

 help COMMAND

=head1 OPTIONS

Optionally svk helps can pipe through a pager, for it is easier to
read if the output is too long. For using this feature, please
set environment variable PAGER to some pager program.
For example:

    # bash, zsh users
    export PAGER='/usr/bin/less'

    # tcsh users
    setenv PAGER '/usr/bin/less'

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 COPYRIGHT

Copyright 2003-2005 by Chia-liang Kao E<lt>clkao@clkao.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
