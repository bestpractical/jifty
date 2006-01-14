use warnings;
use strict;

package Jifty::Script::Action;
use base qw/App::CLI::Command/;

use Jifty::Everything;

=head1 NAME

Jifty::Script::Action - Add an action class to your Jifty application

=head1 DESCRIPTION

This creates a skeleton of a new action class for your jifty
application, complete with a skeleton of a test suite for it,
as well.

=head1 API

=head2 options

There are only two possible options to this script:

=over

=item --name NAME (required)

Name of the action class.

=item --force

By default, this will stop and warn you if any of the files it is
going to write already exist.  Passing the --force flag will make it
overwrite the files.

=back

=cut

sub options {
    (
     'n|name=s' => 'name',
     'force'    => 'force',
    )
}

=head2 run

Creates a skeleton file under C<lib/I<ApplicationClass>/Action/I<Action>>, as
well as a skeleton tests file.

=cut

sub run {
    my $self = shift;
    
    my $action = $self->{name} || '';
    die "You need to give your new action a --name\n"
      unless $action =~ /\w+/;

    Jifty->new( no_handle => 1 );
    my $root = Jifty::Util->app_root;
    my $appclass = Jifty->config->framework("ApplicationClass");
    my $appclass_path =  File::Spec->catfile(split(/::/,Jifty->config->framework("ApplicationClass")));

    my $actionFile = <<"EOT";
use strict;
use warnings;

=head1 NAME

@{[$appclass]}::Action::@{[$action]}

=cut

package @{[$appclass]}::Action::@{[$action]};
use base qw/@{[$appclass]}::Action Jifty::Action/;

=head2 arguments

=cut

sub arguments {
    # This should return an arrayref of arguments
}

=head2 take_action

=cut

sub take_action {
    my \$self = shift;
    
    # Custom action code
    
    \$self->report_success if not \$self->result->failure;
    
    return 1;
}

=head2 report_success

=cut

sub report_success {
    my \$self = shift;
    # Your success message here
    \$self->result->message('Success');
}

1;

EOT


    my $testFile = <<"EOT";
#!/usr/bin/perl
use warnings;
use strict;

=head1 DESCRIPTION

A (very) basic test harness for the $action action.

=cut

use Jifty::Test tests => 1;

# Make sure we can load the action
use_ok('@{[$appclass]}::Action::@{[$action]}');

EOT

    $self->_write("$root/lib/$appclass_path/Action/$action.pm" => $actionFile,
                  "$root/t/00-action-$action.t" => $testFile,
                 );
}

sub _mkpath {
    my $self = shift;
    my @parts = File::Spec->splitdir( shift );
    for (0..$#parts) {
        my $path = File::Spec->catdir(@parts[0..$_]);
        next if -e $path and -d $path;
        print("Creating directory $path\n");
        mkdir $path or die "Can't create $path: $!";
    }
}

sub _write {
    my $self = shift;
    my %files = (@_);
    my $halt;
    for my $path (keys %files) {
        my ($volume, $dir, $file) = File::Spec->splitpath($path);

        # Make sure the directories we need are there
        $self->_mkpath($dir);

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
