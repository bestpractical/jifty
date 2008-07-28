package Multipage::Action::BigTest;

use base 'Jifty::Action::Multipage';

use Jifty::Param::Schema;
use Jifty::Action schema {

param age =>
    label is "Age", is mandatory;

param email =>
    label is 'Email', is mandatory;

param name =>
    label is "Name", is mandatory;

};

sub validate_email {
    my $self = shift;
    my $address = shift;

    return unless $self->has_argument( "email" );
    return $self->validation_error( email => "Not an email address")
      unless $address =~ /@/;
    return $self->validation_ok( "email" );
}

sub validate_name {
    my $self = shift;
    my $name = shift;

    return unless $self->has_argument( "name" );
    return $self->validation_error( name => "Not alex" )
      unless $name eq "alex";
    return $self->validation_ok( "name" );
}

sub validate_age {
    my $self = shift;
    my $age = shift;

    return unless $self->has_argument( "age" );
    return $self->validation_error( age => "Too young" )
      unless $age > 18;
    return $self->validation_ok( "age" );
}

sub take_action {
    my $self = shift;
    my $name = $self->argument_value("name");
    my $email = $self->argument_value("email");
    my $age = $self->argument_value("age");
    $self->result->message("All done, '$name', '$email', '$age'!");
}

1;
