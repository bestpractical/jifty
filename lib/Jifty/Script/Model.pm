use warnings;
use strict;

package Jifty::Script::Model;
use base qw/Jifty::Script/;

=head1 NAME

Jifty::Script::Model - Add a model class to your Jifty application

=head1 SYNOPSIS

    jifty model --name MyFirstModel
    jifty model --name MyFirstModel --force

  Options:
    --name <name>      name of the model
    --force            overwrite files

    --help             brief help message
    --man              full documentation

=head1 DESCRIPTION

Creates a skeleton model file.

=head2 options

=over 8

=item B<--name> NAME (required)

Name of the model class.

=item B<--force>

By default, this will stop and warn you if any of the files it is
going to write already exist.  Passing the --force flag will make it
overwrite the files.

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
        'force' => 'force',
    )
}

=head1 DESCRIPTION

This creates a skeleton of a new model class for your jifty
application, complete with a skeleton of a test suite for it, as well.

=head1 METHODS

=head2 run

Creates a skeleton file under C<lib/I<ApplicationClass>/Model/I<Model>>, as
well as a skeleton tests file.

=cut

sub run {
    my $self = shift;
    
    $self->print_help;

    my $model = $self->{name} || '';
    $self->print_help("You need to give your new model a --name")
      unless $model =~ /\w+/;

    Jifty->new( no_handle => 1 );
    my $root = Jifty::Util->app_root;
    my $appclass = Jifty->config->framework("ApplicationClass");
    my $appclass_path = File::Spec->catfile(split (/::/, $appclass));

    my $modelFile = <<"EOT";
use strict;
use warnings;

package @{[$appclass]}::Model::@{[$model]};
use Jifty::DBI::Schema;

use @{[$appclass]}::Record schema {

};

# Your model-specific methods go here.

1;

EOT


    my $testFile = <<"EOT";
#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the $model model.

=cut

use Jifty::Test tests => 11;

# Make sure we can load the model
use_ok('@{[$appclass]}::Model::@{[$model]}');

# Grab a system user
my \$system_user = @{[$appclass]}::CurrentUser->superuser;
ok(\$system_user, "Found a system user");

# Try testing a create
my \$o = @{[$appclass]}::Model::@{[$model]}->new(current_user => \$system_user);
my (\$id) = \$o->create();
ok(\$id, "$model create returned success");
ok(\$o->id, "New $model has valid id set");
is(\$o->id, \$id, "Create returned the right id");

# And another
\$o->create();
ok(\$o->id, "$model create returned another value");
isnt(\$o->id, \$id, "And it is different from the previous one");

# Searches in general
my \$collection =  @{[$appclass]}::Model::@{[$model]}Collection->new(current_user => \$system_user);
\$collection->unlimit;
is(\$collection->count, 2, "Finds two records");

# Searches in specific
\$collection->limit(column => 'id', value => \$o->id);
is(\$collection->count, 1, "Finds one record with specific id");

# Delete one of them
\$o->delete;
\$collection->redo_search;
is(\$collection->count, 0, "Deleted row is gone");

# And the other one is still there
\$collection->unlimit;
is(\$collection->count, 1, "Still one left");

EOT

    $self->_write("$root/lib/$appclass_path/Model/$model.pm" => $modelFile,
                  "$root/t/00-model-$model.t" => $testFile,
                 );
}

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
