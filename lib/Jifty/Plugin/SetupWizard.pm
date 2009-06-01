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
            {
                template => 'language',
                header   => 'Choose a Language',
            },
            {
                template => 'database',
                header   => 'Database',
            },
            {
                template => 'web',
                header   => 'Web',
            },
        ]);
    }
}

sub add_step {
    my $self = shift;
    my %step = @_;

    push @{ $self->steps }, \%step;
}

1;

