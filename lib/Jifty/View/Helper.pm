use warnings;
use strict;

package Jifty::View::Helper;
use base qw/Jifty::Object Class::Accessor/;

=head2 new

View helpers must be constructed with keyword arguments.  L<Jifty::View::Helper>
expects a C<moniker> argument; subclasses may expect other arguments.
Subclasses should call C<$self = $class->SUPER::new(@_)> at the B<top> of their
C<new> to set up the moniker and initial state.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my %args = (moniker => undef, @_);

    $self->moniker($args{'moniker'});
    $self->{'state'} = {};

    $self->fill_state_from_request;

    return $self;
}

=head2 state STATENAME, [VALUE]

Gets or sets the value of the state variable STATENAME.

=cut

sub state {
    my $self = shift;
    my $key  = shift;

    $self->{'state'}{$key} = shift if @_;
    $self->{'state'}{$key};
} 

=head2 moniker [VALUE]

Gets or sets the helper's moniker.

=cut

__PACKAGE__->mk_accessors('moniker');

=head2 fill_state_from_request

If the incoming L<Jifty::Request> had a helper with a moniker that matches this
helper's moniker, copy state from the request into the helper.

=cut

sub fill_state_from_request {
    my $self = shift;

    my $request_helper = Jifty->framework->request->helper( $self->moniker );

    return unless $request_helper;

    for my $state_name (keys %{ $request_helper->states} ) {
        $self->state($state_name, $request_helper->state($state_name));
    } 
} 

1;
