use strict;
use warnings;

package TestApp::Action::ChangeSomething;
use base qw/ TestApp::Action::UpdateSomething /;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param direction =>
        is mandatory,
        default is 'forward',
        valid_values are qw/
            forward
            reverse
        /,
        ;
};

sub take_action {
    my $self = shift;

    my $test3 = $self->argument_value('test3');
    if ($self->argument_value('direction') eq 'reverse'
            and defined $test3) {

        $test3 = reverse $test3;
        $self->argument_value( test3 => $test3 );
    }

    $self->argument_value( test3 => $test3 . $self->argument_value('append') )
        if defined $self->argument_value('append');

    $self->SUPER::take_action(@_);
}

1
