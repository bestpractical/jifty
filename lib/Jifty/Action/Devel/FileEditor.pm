package Jifty::Action::Devel::FileEditor;

use base qw/Jifty::Action/;
use File::Spec;


sub new {
    my $class = shift; my $self = $class->SUPER::new(@_);
    $self->get_default_content; 
    return($self);

}


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
            $self->argument_value(source_path => $qualified_path);
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

sub validate_destination_path {
    my $self = shift;
    my $value = shift;
    $self->{'write_to'} =  ($value or $self->argument_value('source_path'));
    unless ($self->{'write_to'}) {
        return  $self->validation_error( destination_path => "No destination path set. Where should I write this file?");
    }
    if (-f $self->{'write_to'} and not -w $self->{'write_to'}) {
        return  $self->validation_error( destination_path => "Can't save the file to ".$self->{'write_to'});

    }
    return $self->validation_ok;
}

sub take_action {
    my $self = shift;
    
    my $dest  = $self->{'write_to'};
    warn "Making directory $dest";
    $self->_make_path($dest);
    my $writehandle = IO::File->new();
    $writehandle->open(">$dest") || die "Couldn't open $dest for writing: ".$!;
    warn YAML::Dump($self);
    $writehandle->print( $self->argument_value('content')) || die " Couldn't write to $dest: ".$!;
    $writehandle->close() || die "Couldn't close filehandle $dest ".$!;
    $self->result->message("Updated $dest");
    $self->redirect('/=/edit/component/'.$dest);

}


sub _make_path {

    my $self = shift;
    my $whole_path = shift;
    my @dirs = File::Spec->splitdir( $whole_path );
    pop @dirs; # get the filename ripped off the directory
    my $path ='';
    foreach my $dir ( @dirs) {
        $path = File::Spec->catdir($path, $dir);
        if (-d $path) { next }
        if (-w $path) { die "$path not writable"; }
        
        
        mkdir($path) || die "Couldn't create directory $path: $!";
    }

}



1;
