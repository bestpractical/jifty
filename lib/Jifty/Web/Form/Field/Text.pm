use warnings;
use strict;

package Jifty::Web::Form::Field::Text;
use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Web::Form::Field::Text - Renders as a small text field

=head1 METHODS

=cut

our $VERSION = 1;

=head2 classes

Output text fields with the class 'text'

=cut

sub classes {
    my $self = shift;
    return join(' ', 'text', ($self->SUPER::classes));
}


=head2 handler_allowed HANDLER_NAME

Returns 1 if the handler (e.g. onclick) is allowed.  Undef otherwise.

=cut

sub handler_allowed {
    my $self = shift;
    my ($handler) = @_;

    return $self->SUPER::handler_allowed($handler) ||
           {onselect => 1}->{$handler};

}


1;
