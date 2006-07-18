package Continuations::Action::CrossBridge;

use Jifty::Param::Schema;
use Jifty::Action schema {

param 'name';
param 'quest';
param 'colour' => valid_values are ("Blue, I mean greeeeeen!", "Green");

};

sub validate_quest {
    my $self = shift;
    my $value = shift ||'';
    if ($value !~ /grail/i) {
        return $self->validation_error( quest => "Something about the grail" );
    }
    return $self->validation_ok( 'quest' );
}

sub validate_colour {
    my $self = shift;
    my $value = shift ||'';
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
