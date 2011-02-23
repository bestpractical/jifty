package Jifty::Script::Adopt;

use warnings;
use strict;

use base qw/Jifty::Script/;

use File::Copy ();
use File::Spec ();
use File::Basename ();

use Jifty::Util;

=head1 NAME

Jifty::Script::Adopt - localize a stock jifty component

=head1 SYNOPSIS

    jifty adopt web/templates/_elements/nav
    jifty adopt --ls web/static/

 Options:
   --ls <path>        list components for adoption
   --tree <path>      list components for adoption

   --help             brief help message
   --man              full documentation

=head1 DESCRIPTION

This script will let you create an application-specific replacement for stock
Jifty components. For various reasons, Jifty does not actually create these
skeleton files in your application's directory tree. While this makes upgrading
easier, it can make finding which files to create a little difficult.

=head2 options

=over 8

=item B<-l>, B<--ls> PATH

Lists the contents of the stock components path.

=item B<-t>, B<--tree> PATH

Lists the contents of the stock components path recursively.

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=cut

sub options {
    my $self = shift;
    return (
        $self->SUPER::options,
        'l|ls' => 'list',
        't|tree' => 'tree',
    )
}

=head1 DESCRIPTION

Creates directories and copies files for you, launching $ENV{EDITOR} if
it is defined.

=head1 METHODS

=head2 run

=cut

sub run {
    my $self = shift;
    my (@args) = @_;

    $self->print_help();

    my $filename = shift(@args);
    $filename ||= '';
    my @parts = split(/[\/\\]/, $filename);

    if($self->{list}) {
        my $dir = File::Spec->catfile(Jifty::Util->share_root, @parts);
        unless(-d $dir) {
            warn "no such directory $dir";
        }
        opendir(my $dh, $dir) or die;
        my @files = sort(grep(! /^\.\.?$/, readdir($dh)));
        my @dirs;
        # sort directories first
        for(my $i = 0; $i < @files; $i++) { # List::MoreUtil::part ?
            if(-d File::Spec->catfile($dir, $files[$i])) {
                push(@dirs, splice(@files, $i, 1) . '/');
                $i--;
            }
        }
        print join("\n", @dirs, @files, '');

        exit;
    }
    elsif($self->{tree}) {
        # Just punting here, maybe don't need this usage except when you
        # have no tree command?  Oh, the irony.
        my $dir = File::Spec->catfile(Jifty::Util->share_root, @parts);
        unless(-d $dir) {
            warn "no such directory $dir";
        }

        system('tree', $dir) and die "oops $!";

        exit;
    }

    unless($filename) {
        die "usage: jifty adopt <filename>\n";
    }

    my $share = 'share';
    unless(-d $share) {
        die "must be run from your app directory\n";
    }

    my $source = File::Spec->catfile(Jifty::Util->share_root, @parts);
    (-e $source) or die "no such source file '$source'\n";

    my $dest = File::Spec->catfile($share, @parts);

    unless(-d File::Basename::dirname($dest)) {
        Jifty::Util->make_path($dest);
    }

    if(-e $dest) {
        print "$dest exists, overwrite? [n] ";
        chomp(my $ans = <STDIN>); $ans ||= 'n';
        exit 1 unless(lc($ans) eq 'y');
    }
    File::Copy::copy($source, $dest) or die "copy failed $!";
    chmod(0644, $dest) or die "cannot change mode $!";

    # TODO put an option on that?
    if($ENV{EDITOR}) {
        system($ENV{EDITOR}, $dest);
    }

} # end run

# original author:  Eric Wilhelm

1;
# vim:ts=4:sw=4:et:sta
