use warnings;
use strict;

=head1 NAME

Jifty::Action::Redirect

=cut

package Jifty::Action::Redirect;
use base qw/Jifty::Action/;

=head2 new

By default, redirect actions happen as late as possible in the run
order.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    # XXX TODO This is wrong -- it should be -1 or some equivilent, so
    # it is worted last all the time.
    $self->order(100) unless defined $self->order;
    return $self;
}

=head2 arguments

The fields for C<Redirect> are:

=over 4

=item url


=back

=cut

sub arguments {
        {
            url => { constructor => 1 },
        }

}

=head2 take_action

Set up a redirect

=cut

sub take_action {
    my $self = shift;
    return 1 unless ($self->argument_value('url'));
    return 0 unless Jifty->web->response->success;

    my $page = $self->argument_value('url');

    Jifty->web->next_page($page);
    return 1;
}

1;

