package TestApp::Action::DoSomething;

use base qw/Jifty::Action/;

sub arguments {
    return({
        email => {
            label => 'Email',
            ajax_canonicalizes => 1,
            ajax_validates => 1,
        }
    });
}

sub canonicalize_email {
    my $self = shift;
    my $address = shift;
    
    return lc($address);
}

sub validate_email {
    my $self = shift;
    my $address = shift;

    if($address =~ /bad\@email\.com/) {
        return $self->validation_error('email', "Bad looking email");
    } elsif ($address =~ /warn\@email\.com/) {
        return $self->validation_warning('email', "Warning for email");
    }
    return $self->validation_ok('email');
}

sub take_action {
    my $self = shift;

    $self->result->message("Something happened!");
}

1;
