package Jifty::Plugin::SetupWizard;
use strict;
use warnings;
use base 'Jifty::Plugin';

__PACKAGE__->mk_accessors(qw(steps));

sub prereq_plugins { 'Config' }

sub init {
    my $self = shift;
    return if $self->_pre_init;

    my %opt = @_;

    if ($opt{steps}) {
        $self->steps($opt{steps});
    }
    else {
        $self->steps([
            # Not sure this is worth doing quite yet.
#            {
#                template => 'language',
#                header   => 'Choose a Language',
#            },
            {
                template => 'database',
                header   => 'Database',
            },
            {
                template => 'web',
                header   => 'Web',
            },
            {
                template => 'finalize',
                header   => 'Finalize',
            },
        ]);
    }
}

sub add_step {
    my $self = shift;
    my %step = @_;

    # Keep finalize at the end
    if ($self->steps->[-1]->{template} eq 'finalize') {
        splice @{ $self->steps }, -1, 0, \%step;
    }
    else {
        push @{ $self->steps }, \%step;
    }
}

1;

