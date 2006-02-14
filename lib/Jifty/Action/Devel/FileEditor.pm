package Jifty::Action::Devel::FileEditor;

use base qw/Jifty::Action/;
use File::Spec;


=head1 NAME

Jifty::Action::Devel::FileEditor

=head1 DESCRIPTION

This action allows you to edit mason components (and eventually libraries)
using Jifty's I<Action> system.  It should only be enabled when you're
running Jifty in C<DevelMode>. 

=head1 WARNING

B<THIS ACTION LETS YOU REMOTELY EDIT EXECUTABLE CODE>.

B<THIS IS DANGEROUS>



=cut

=head2 new

Create a new C<FileEditor> action.

=cut

sub new {
    my $class = shift; 
    my $self = $class->SUPER::new(@_);
    $self->sticky_on_success(1);
    $self->get_default_content; 
    return($self);

}

=head2 arguments

Sets up this action's arguments.

=over

=item path

Where to save the file

=item file_type

(One of mason_component or library)

=item source_path

Where to read the file from.

=item destination_path

Where to write the file to. If the current user can't write to 
the source_path, defaults to something inside the app's directory.

=item content

The actual content of the file we're editing.


=back

=cut


sub arguments {
    my $self = shift;

    {   path      => { type => 'text', constructor => 1 },
        file_type => {
            default      => 'mason_component',
            render_as    => 'Select',
            valid_values => [qw/mason_component library/],
            constructor  => 1
        },
        source_path      => { type => 'text', constructor => 1 },
        destination_path => { type => 'text', ajax_validates=> 1, label => 'Save as' },
        content => { render_as => 'Textarea', cols => 80, rows => 25 },

    }

}


=head2 get_default_content

Finds the version of the C<source_path> (of type C<file_type>) and loads it into C<content>.


=cut

sub get_default_content {
    my $self = shift;

    # Don't override content we already have
    return if ($self->argument_value('content'));
    my $path = $self->argument_value('source_path');
    my $type = $self->argument_value('file_type');
    my $out = '';
    my %cfg = Jifty->handler->mason_config;
    
    my $local_template_base;
    foreach my $item (@{$cfg{comp_root}}) {
        $local_template_base = $item->[1] if ($item->[0] eq 'application');
        my $qualified_path = File::Spec->catfile($item->[1],$path);
        if (-f $qualified_path and -r $qualified_path)  {
            $self->argument_value(qualified_path => $qualified_path);
            my $filehandle;
            open ($filehandle, "<$qualified_path")||die "Couldn't read $qualified_path: $!";
            $out = join('',<$filehandle>);
            close($filehandle);
            last; # We want the first match
        }
    }
    $self->argument_value(content => $out);
    $self->argument_value(destination_path => File::Spec->catfile($local_template_base, $path));
}

=head2 validate_destination_path PATH

Returns true if the user can write to the directory C<PATH>. False otherwise. Should be refactored to a C<path_writable> routine and a trivial validator.

=cut

sub validate_destination_path {
    my $self = shift;
    my $value = shift;
    $self->{'write_to'} = $value;
    unless ($self->{'write_to'}) {
        return  $self->validation_error( destination_path => "No destination path set. Where should I write this file?");
    }
    if (-f $self->{'write_to'} and not -w $self->{'write_to'}) {
        return  $self->validation_error( destination_path => "Can't save the file to ".$self->{'write_to'});
    }
    return $self->validation_ok;
}


=head2 take_action

Writes the C<content> out to the C<destination_path>.

=cut

sub take_action {
    my $self = shift;
    my $dest  = $self->{'write_to'};
    my @dirs = File::Spec->splitdir( $dest );
    pop @dirs; # discard filename. we only want to make the directory ;)
    Jifty::Util->make_path( File::Spec->catdir(@dirs));
    my $writehandle = IO::File->new();
    $writehandle->open(">$dest") || die "Couldn't open $dest for writing: ".$!;
    $writehandle->print( $self->argument_value('content')) || die " Couldn't write to $dest: ".$!;
    $writehandle->close() || die "Couldn't close filehandle $dest ".$!;
    $self->result->message("Updated $dest");
}



1;
