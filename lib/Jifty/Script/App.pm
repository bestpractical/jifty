use warnings;
use strict;

package Jifty::Script::App;
use base 'App::CLI::Command';

use YAML;
use File::Copy;

=head1 NAME

Jifty::Script::App - Create the skeleton of a Jifty application

=head1 DESCRIPTION

If you want to create a Jifty application, 

=cut

sub options {
    (
     'n|name=s' => 'name',
    )
}

sub run {
    my $self = shift;

    my $prefix = $self->{name} ||''; 

    unless ($prefix =~ /\w+/ ) { die "You need to give your new Jifty app a --name"."\n";}

    my $modname = $self->{modname} || ucfirst($prefix);

    print("Creating new application ".$self->{name}."\n");
    mkdir($prefix);

    foreach my $dir ($self->directories) {
        $dir =~ s/__APP__/$modname/;
        print("Creating directory $dir\n");
        mkdir( "$prefix/$dir");

    }

    # Copy our running copy of 'jifty' to bin/jifty
    copy($0, "$prefix/bin/jifty");
    # Mark it executable
    chmod(0555, "$prefix/bin/jifty");

}

sub directories {
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

