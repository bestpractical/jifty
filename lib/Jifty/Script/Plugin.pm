use warnings;
use strict;

package Jifty::Script::Plugin;
use base qw/Jifty::Script Class::Accessor::Fast/;

use File::Copy;
use Jifty::Config;
use Jifty::YAML;
use File::Basename;

__PACKAGE__->mk_accessors(qw/prefix dist_name mod_name lib_dir/);


=head1 NAME

Jifty::Script::Plugin - Create the skeleton of a Jifty plugin

=head1 SYNOPSIS
    
    jifty plugin --name NewPlugin
    jifty plugin --help
    jifty plugin --man

=head1 DESCRIPTION

Creates a skeleton of a new L<Jifty::Plugin>.

=head2 options

=over 8

=item --name

This script only takes one option, C<--name>, which is required; it is
the name of the plugin to create; this will be prefixed with
C<Jifty::Plugin::> automatically.  Jifty will create a directory with
that name, and place all of the files it creates inside that
directory.

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

=head1 METHODS

=head2 run

Create a directory for the plugin, a skeleton directory structure, and
a C<Makefile.PL> for your plugin.

=cut

sub run {
    my $self = shift;
    $self->print_help();

    $self->prefix( $self->{name} ||''); 

    unless ($self->prefix =~ /\w+/ ) { die "You need to give your new Jifty plugin a --name"."\n";}
    $self->prefix( $self->prefix );

    # Turn my-plugin-name into My::Plugin::Name.
    $self->mod_name ("Jifty::Plugin::" . join ("::", map { ucfirst } split (/\-/, $self->prefix)));
    $self->dist_name("Jifty-Plugin-".$self->prefix);
    $self->lib_dir(join("/",grep{$_} split '::', $self->mod_name));

    print("Creating new plugin ".$self->mod_name."\n");
    $self->_make_directories();
    $self->_write_makefile();
    $self->_write_default_files();
}

sub _write_makefile {
    my $self = shift;
    my $prefix = $self->prefix;
    # Write a makefile
    open(MAKEFILE, ">$prefix/Makefile.PL") or die "Can't write Makefile.PL: $!";
    print MAKEFILE <<"EOT";
use inc::Module::Install;
name('@{[$self->dist_name]}');
version('0.01');
requires('Jifty' => '@{[$Jifty::VERSION]}');

install_share;

WriteAll;
EOT
    close MAKEFILE;
} 

sub _write_default_files {
    my $self = shift;
    my $mod_name = $self->mod_name;
    my $prefix = $self->prefix;
    my $lib = $self->lib_dir;
    open(PLUGIN, ">$prefix/lib/$lib.pm") or die "Can't write $prefix/$lib.pm: $!";
    print PLUGIN <<"EOT";
use strict;
use warnings;

package $mod_name;
use base qw/Jifty::Plugin/;

# Your plugin goes here.  If it takes any configuration or arguments, you
# probably want to override L<Jifty::Plugin/init>.

1;
EOT
    close PLUGIN;

    open(DISPATCHER, ">$prefix/lib/$lib/Dispatcher.pm") or die "Can't write $prefix/lib/$lib/Dispatcher.pm: $!";
    print DISPATCHER <<"EOT";
use strict;
use warnings;

package @{[$mod_name]}::Dispatcher;
use Jifty::Dispatcher -base;

# Put any plugin-specific dispatcher rules here.

1;
EOT
}

sub _make_directories {
    my $self = shift;

    mkdir($self->prefix);
    my @dirs = qw/ lib /;
    my @dir_parts = split('/',$self->lib_dir);
    push @dirs, join('/', 'lib', @dir_parts[0..$_]) for 0..@dir_parts-1;

    @dirs = (@dirs, $self->_directories); 

    foreach my $dir (@dirs) {
        $dir =~ s/__LIB__/$self->lib_dir/e;
        print("Creating directory $dir\n");
        mkdir( $self->prefix."/$dir") or die "Can't create ". $self->prefix."/$dir: $!";
    }
}

sub _directories {
    return qw/
        doc
        share
        share/po
        share/web
        share/web/templates
        share/web/static
        lib/__LIB__/Model
        lib/__LIB__/Action
        t
    /;
}

1;
