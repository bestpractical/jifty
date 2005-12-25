package JFDI::Generator;
use base qw/App::CLI/;

sub dispatch { 
    my $self = shift;
    $self->SUPER::dispatch(@_);
}


1;
