use warnings;
use strict;

package Jifty::Script::Action;
use base qw/Jifty::Script/;

=head1 NAME

Jifty::Script::Action - Add an action class to your Jifty application

=head1 SYNOPSIS

    jifty action --name NewAction
    jifty action --help
    jifty action --man

=head1 OPTIONS

There are only two possible options to this script:

=over 8

=item --name NAME (required)

Name of the action class.

=item --force

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
        'force'    => 'force',
    );
}

=head1 DESCRIPTION

This creates a skeleton of a new action class for your jifty
application, complete with a skeleton of a test suite for it,
as well.

=head1 METHODS

=head2 run

Creates a skeleton file under C<lib/I<ApplicationClass>/Action/I<Action>>, as
well as a skeleton tests file.

=cut

sub run {
    my $self = shift;

    $self->print_help;
    
    my $action = $self->{name} || '';
    $self->print_help("You need to give your new action a --name")
        unless $action =~ /\w+/;

    Jifty->new( no_handle => 1 );
    my $root = Jifty::Util->app_root;
    my $appclass = Jifty->config->framework("ApplicationClass");
    my $appclass_path =  File::Spec->catfile(split(/::/,$appclass));

    # Detect if they're creating an App::Action::UpdateWidget, for example
    my $subclass = "Jifty::Action";
    if ($action =~ /^(Create|Search|Execute|Update|Delete)(.+)$/) {
        my($type, $model) = ($1, $2);
        $model = Jifty->app_class( Model => $model );
        $subclass = Jifty->app_class( Action => Record => $type )
            if grep {$_ eq $model} Jifty->class_loader->models;
    }

    my $actionFile = <<"EOT";
use strict;
use warnings;

=head1 NAME

@{[$appclass]}::Action::@{[$action]}

=cut

package @{[$appclass]}::Action::@{[$action]};
use base qw/@{[$appclass]}::Action @{[$subclass]}/;

use Jifty::Param::Schema;
use Jifty::Action schema {

};

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
#!/usr/bin/env perl
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
