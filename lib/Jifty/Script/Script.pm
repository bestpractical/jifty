use warnings;
use strict;

package Jifty::Script::Script;
use base qw/ Jifty::Script /;

=head1 NAME

Jifty::Script::Script - Add a new Jifty script to your Jifty application

=head1 SYNOPSIS

    jifty script --name my_new_script
    jifty script --name my_new_script --force
    jifty script --help
    jifty script --man

=head1 DESCRIPTION

Add a skeleton command-line script file.

=head2 options

=over 8

=item --name NAME (required)

Name of the script to create.

=item --force

By default, this will stop and warn you if any of the files it is going to write already exist. Passing the --force flag will make it overwrite the files.

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
        'n|name=s' => 'name',
        'force'    => 'force',
    )
}

=head1 DESCRIPTION

This creates a skeleton of a new script file for your Jifty application. Often such a script is needed for cron jobs, annual maintenance work, and any other server-side activity that would benefit from a command-line script.

=head1 METHODS

=head2 run

Creates a skeleton file under C<bin/I<script>>.

TODO Should this create skeleton test files too?

=cut

sub run {
    my $self = shift;

    $self->print_help;

    my $script = $self->{name};
    $self->print_help("You need to give your new script a --name")
        unless defined $script;

    Jifty->new( no_handle => 1 );
    my $root = Jifty::Util->app_root;

    my $script_file = <<"END_OF_SCRIPT";
#!/usr/bin/env perl
use strict;
use warnings;

use Jifty;
BEGIN { Jifty->new }

# Your script-specific code goes here.

END_OF_SCRIPT

    $self->_write("$root/bin/$script" => $script_file);
}

# TODO This should be moved to Jifty::Util or somewhere else so all these
# scripts don't duplicate it!
sub _write {
    my $self = shift;
    my %files = (@_);
    my $halt;
    for my $path (keys %files) {
        my ($volume, $dir, $file) = File::Spec->splitpath($path);

        # Make sure the directories we need are there
        Jifty::Util->make_path($dir);

        # If it already exists, bail
        if (-e $path and not $self->{force}) {
            print "File $path exists already; Use --force to overwrite\n";
            $halt = 11;
        }
    }
    exit if $halt;

    # Now that we've san-checked everything, we can write the files
    for my $path (keys %files) {
        print "Writing file $path\n";
        # Actually write the file out
        open(FILE, ">$path")
          or die "Can't write to $path: $!";
        print FILE $files{$path};
        close FILE;
    }
}

1;
