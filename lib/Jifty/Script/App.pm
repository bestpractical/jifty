use warnings;
use strict;

package Jifty::Script::App;
use base qw(Jifty::Script Class::Accessor::Fast);

use File::Copy;
use Jifty::Config;
use Jifty::YAML;
use File::Basename;

__PACKAGE__->mk_accessors(qw/prefix dist_name mod_name/);


=head1 NAME

Jifty::Script::App - Create the skeleton of a Jifty application

=head1 SYNOPSIS

  jifty --name MyApp  Creates an application

 Options:
   --name             application name

   --help             brief help message
   --man              full documentation

=head1 DESCRIPTION

This script creates the skeleton of your application. See
L<Jifty::Manual::Tutorial> for more information.

=head2 options

=over 8

=item B<--name>

Required option. It is the name of the application to create.
Jifty will create a directory with that name, and place all of
the files it creates inside that directory.

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
    )
}

=head1 DESCRIPTION

Creates a skeleton of a new Jifty application.  See
L<Jifty::Manual::Tutorial> for an example of its use.

=head1 METHODS

=head2 run

Create a directory for the application, a skeleton directory
structure, and a C<Makefile.PL> for you application.

=cut

sub run {
    my $self = shift;

    my $name = $self->{'name'};
    $name = '' unless defined $name;
    $name =~ s/::/-/g;
    $self->prefix( $name ); 

    $self->print_help;
    unless ( $self->prefix =~ /\w+/ ) {
        $self->print_help("You need to give your new Jifty app a --name");
    }

    # Turn my-app-name into My::App::Name.

    $self->mod_name (join ("::", split (/\-/, $self->prefix)));
    my $dist = $self->mod_name;
    $self->dist_name($self->prefix);

    print("Creating new application ".$self->mod_name."\n");
    $self->_make_directories();
    $self->_install_jifty_binary();
    $self->_write_makefile();
    $self->_write_dotpsgi();
    $self->_write_config();


}

sub _install_jifty_binary {
    my $self = shift;
    my $prefix = $self->prefix;
    my $basename = basename($0);

    # Copy our running copy of 'jifty' to bin/jifty
    copy($0, "$prefix/bin/$basename");
    # Mark it executable
    chmod(0555, "$prefix/bin/$basename");

    # Do the same for .bat if we are on a DOSish platform
    if (-e "$0.bat") {
        copy("$0.bat", "$prefix/bin/$basename.bat");
        chmod(0555, "$prefix/bin/$basename.bat");
    }
}



sub _write_makefile {
    my $self = shift;
    my $mod_name = $self->mod_name;
    my $prefix = $self->prefix;
    # Write a makefile
    open(MAKEFILE, ">$prefix/Makefile.PL") or die "Can't write Makefile.PL: $!";
    print MAKEFILE <<"EOT";
use inc::Module::Install;

name        '$mod_name';
version     '0.01';
requires    'Jifty' => '@{[$Jifty::VERSION]}';

WriteAll;
EOT
    close MAKEFILE;
} 

sub _write_dotpsgi {
    my $self = shift;
    my $prefix = $self->prefix;
    open(my $fh, ">$prefix/app.psgi") or die "Can't write app.psgi: $!";
    print $fh <<"EOT";
use Jifty;
Jifty->new;
Jifty->handler->psgi_app;
EOT
}

sub _make_directories {
    my $self = shift;

    mkdir($self->prefix) or die("Can't create " . $self->prefix . ": $!");
    my @dirs = qw( lib );
    my @dir_parts = split('::',$self->mod_name);
    my $lib_dir = "";
    foreach my $part (@dir_parts) {
        $lib_dir .= '/' if length $lib_dir;
        $lib_dir .=  $part;
        push @dirs, "lib/$lib_dir";
    }

    @dirs = (@dirs, $self->_directories); 

    foreach my $dir (@dirs) {
        $dir =~ s/__APP__/$lib_dir/;
        print("Creating directory @{[$self->prefix]}/$dir\n");
        mkdir( $self->prefix."/$dir") or die "Can't create ". $self->prefix."/$dir: $!";

    }
}
sub _directories {
    return qw(
        bin
        etc
        doc
        log
        var
        var/mason
        share
        share/po
        share/web
        share/web/templates
        share/web/static
        lib/__APP__/Model
        lib/__APP__/Action
        t
    );
}


sub _write_config {
    my $self = shift;
    my $cfg = Jifty::Config->new(load_config => 0);
    my $default_config = $cfg->initial_config($self->dist_name);
    my $file = join("/",$self->prefix, 'etc','config.yml');

    # Open the file ourselves so we can print a comment to it before the
    # default YAML config
    open my $fh, '>', $file
        or die "Can't create configuration file '$file': $!\n";
    binmode $fh, ':utf8';

    print("Creating configuration file $file\n");

    print $fh "# See perldoc Jifty::Config for more information about config files\n";
    Jifty::YAML::DumpFile($fh => $default_config);
    close $fh;
}


1;

