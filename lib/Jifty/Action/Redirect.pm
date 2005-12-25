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

=item preserve_helpers

=back

=cut

sub arguments {
        {
            url => { constructor => 1 },
            preserve_helpers => {},
        }

}

=head2 take_action

Set up a redirect

=cut

sub take_action {
    my $self = shift;
    return 1 unless ($self->argument_value('url'));
    return 0 unless Jifty->framework->response->success;

    my $page = $self->argument_value('url');

    my %helper_args = Jifty->framework->request->helpers_as_query_args(split ' ',$self->argument_value('preserve_helpers') || "");

    if (keys %helper_args) {
        $page .= ( $page =~ /\?/ ? ';' : '?' ) . join(";", map {"$_=$helper_args{$_}"} keys %helper_args);
    }

    Jifty->framework->next_page($page);
    return 1;
}

1;

