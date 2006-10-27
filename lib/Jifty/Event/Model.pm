package Jifty::Event::Model;

use warnings;
use strict;
use Carp;
use base qw/Jifty::Event/;


sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->_check() if (Jifty->config->framework('PubSub')->{'Enable'});
    return $self;
}


sub _check {
    my $self = shift;
    for (qw(record_id record_class action_class
        action_arguments timestamp result as_hash_before
        as_hash_after current_user_id)) {
        Carp::confess("$self missing required parameter $_ ")
            unless ( defined $$self->{$_} );
        };
}

1;
