use warnings;
use strict;

package Jifty::Script::App;
use base 'App::CLI::Command';

use YAML;
use File::Copy;

=head1 NAME

Jifty::Script::App - Create the skeleton of a Jifty application

=head1 DESCRIPTION

Creates a skeleton of a new Jifty application.  See
L<Jifty::Manual::Tutorial> for an example of its use.

=head2 options

This script only takes one option, C<--name>, which is required; it is
the name of the application to create.  Jifty will create a directory
with that name, and place all of the files it creates inside that
directory.

=cut

sub options {
    (
     'n|name=s' => 'name',
    )
}

=head2 run

Create a directory for the application, a skeleton directory
structure, and a C<Makefile.PL> for you application.

=cut

sub run {
    my $self = shift;

    my $prefix = $self->{name} ||''; 

    unless ($prefix =~ /\w+/ ) { die "You need to give your new Jifty app a --name"."\n";}

    my $modname = $self->{modname} || ucfirst($prefix);

    print("Creating new application ".$self->{name}."\n");
    mkdir($prefix);

    foreach my $dir ($self->_directories) {
        $dir =~ s/__APP__/$modname/;
        print("Creating directory $dir\n");
        mkdir( "$prefix/$dir") or die "Can't create $prefix/$dir: $!";

    }

    # Copy our running copy of 'jifty' to bin/jifty
    copy($0, "$prefix/bin/jifty");
    # Mark it executable
    chmod(0555, "$prefix/bin/jifty");

    # Write a makefile
    open(MAKEFILE, ">$prefix/Makefile.PL") or die "Can't write Makefile.PL: $!";
    print MAKEFILE <<"EOT";
use inc::Module::Install;
name('$modname');
version('0.01');
requires('Jifty');

WriteAll;
EOT
    close MAKEFILE;
}

sub _directories {
    return qw(
        bin
        etc
        doc
        log
        web
        web/templates
        web/static
        lib
        lib/__APP__
        lib/__APP__/Model
        lib/__APP__/Action
        t
    );
}


1;

