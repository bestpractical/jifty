package Continuations::Action::CrossBridge;

use base qw/Jifty::Action/;

sub arguments {
    {
        name   => {},
        quest  => {},
        colour => {valid_values => ["Blue, I mean greeeeeen!", "Green"]},
    }
}

sub validate_quest {
    my $self = shift;
    my $value = shift;
    if ($value !~ /grail/i) {
        return $self->validation_error( quest => "Something about the grail" );
    }
    return $self->validation_ok( 'quest' );
}

sub validate_colour {
    my $self = shift;
    my $value = shift;
    if ($value =~ /blue/i) {
        return $self->validation_error( colour => "That'll get you thrown off the bridge");
    }
    return $self->validation_ok('colour');
}

sub take_action {
    my $self = shift;

    $self->result->message("You crossed the bridge!");
}

1;
