package TestApp::CurrentUser;

use warnings;
use strict;

use base qw/Jifty::CurrentUser/;

use TestApp::Model::User;

sub _init {
    my $self = shift;
    my %args = (@_);

    if ( delete $args{'_bootstrap'} ) {
        $self->is_bootstrap_user(1);
    } elsif (keys %args) {
        $self->user_object(TestApp::Model::User->new(current_user => $self));
        $self->user_object->load_by_cols(%args);

        # tasty users are superusers
        if ( $self->user_object->tasty == 1 ) {
            $self->is_superuser(1);
        }    
    }
    $self->SUPER::_init(%args);
}

sub current_user_can {
    return 1;
}

1;
