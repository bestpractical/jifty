package Jifty::Event::Model;

use warnings;
use strict;
use Carp;
use base qw/Jifty::Event/;



=head1 NAME

Jifty::Event::Model - Events representing changes to records

=head1 DESCRIPTION

Objects in this class represent changes to Jifty::Record classes (any action on a model class)
as Jifty::Events.

As yet, this functionality is unused.


=cut

=head2 new

creates a new L<Jifty::Event::Model> object.  If C<PubSub> is enabled for your application, 
checks to make sure that this event has the following (under-documented) parameters:

 record_id record_class action_class action_arguments timestamp result as_hash_before as_hash_after current_user_id

=cut


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
