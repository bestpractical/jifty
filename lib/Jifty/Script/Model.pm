use warnings;
use strict;

package Jifty::Script::Model;
use base qw/App::CLI::Command/;

use Jifty::Everything;

=head1 NAME

Jifty::Script::Model - Add a model class to your Jifty application

=head1 DESCRIPTION



=head1 API

=head2 options

=over

=item --name


=back

=cut

sub options {
    (
     'n|name=s' => 'name',
     'force' => 'force',
    )
}

=head2 run

Creates a skeleton file under C<lib/I<Application>/Model/I<Model>>, as
well as a skeleton tests file.

=cut

sub run {
    my $self = shift;
    
    my $model = $self->{name} || '';
    die "You need to give your new model a --name\n"
      unless $model =~ /\w+/;

    my $root = Jifty::Util->app_root;
    my $appname = Jifty::Util->app_name;
    my $path = "$root/lib/$appname/Model/$model.pm";

    my $modelFile = <<"EOT";
package @{[$appname]}::Model::@{[$model]}::Schema;
use Jifty::DBI::Schema;

# You column definitions go here.  See L<Jifty::DBI::Schema> for
# documentation about how to write column definitions.

package @{[$appname]}::Model::@{[$model]};
use base qw/@{[$appname]}::Record/;

# Your model-specific methods go here.

1;

EOT


    my $testFile = <<"EOT";
#!/usr/bin/perl -w
use warnings;
use strict;

=head1 DESCRIPTION

A test harness for the $model model.

=cut


use Test::More no_plan => 1;

# Make sure we load Jifty
use_ok('Jifty');
Jifty->new();

# Make sure we can load the model
use_ok('@{[$appname]}::Model::@{[$model]}');

# Grab a system use
my \$system_user = @{[$appname]}::CurrentUser->superuser;
ok(\$system_user, "Found a system user");

# Try testing a create
my \$o = @{[$appname]}::Model::@{[$model]}->new(current_user => \$system_user);
my (\$id) = \$o->create();
ok(\$id, "$model create returned success");
ok(\$o->id, "New $model has valid id set");
is(\$o->id, \$id, "Create returned the right id");

# And another
\$o->create();
ok(\$o->id, "$model create returned another value");
isnt(\$o->id, \$id, "And it is different from the previous one");

# Searches
my \$collection =  @{[$appname]}::Model::@{[$model]}Collection->new(current_user => \$system_user);
\$collection->unlimit;
is(\$collection->count, 2, "Finds two records");
print \$_->id, "\\n" while \$_ = \$collection->next;

\$collection->limit(column => 'id', value => \$o->id);
is(\$collection->count, 1, "Finds one record with specific id");

EOT

    $self->write("$root/lib/$appname/Model/$model.pm" => $modelFile,
                 "$root/t/00-Model-$model.t" => $testFile,
                );
}

sub mkpath {
    my $self = shift;
    my @parts = File::Spec->splitdir( shift );
    for (0..$#parts) {
        my $path = File::Spec->catdir(@parts[0..$_]);
        next if -e $path and -d $path;
        print("Creating directory $path\n");
        mkdir $path or die "Can't create $path: $!";
    }
} 

sub write {
    my $self = shift;
    my %files = (@_);
    my $halt;
    for my $path (keys %files) {
        my ($volume, $dir, $file) = File::Spec->splitpath($path);

        # Make sure the directories we need are there
        $self->mkpath($dir);

        # If it already exists, bail
        if (-e $path) {
            if ($self->{force}) {
                print "File $path exists; overwriting\n";
            } else {
                print "File $path exists already;\nUse --force to overwrite\n";
                $halt = 1;
            }
        } else {
            print "Writing file $path\n";
        }
    }
    exit if $halt;
    
    # Now that we've san-checked everything, we can write the files
    for my $path (keys %files) {
        # Actually write the file out
        open(FILE, ">$path")
          or die "Can't write to $path: $!";
        print FILE $files{$path};
        close FILE;
    }
}

1;
