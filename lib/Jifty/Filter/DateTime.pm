use warnings;
use strict;

=head1 NAME

Jifty::Filter::DateTime -- A Jifty::DBI filter to work with
                          Jifty::DateTime objects

=head1 DESCRIPTION

Jifty::Filter::DateTime promotes DateTime objects to Jifty::DateTime
objects on load. This has the side effect of setting their time zone
based on the record's current user's preferred time zone, when
available.

=cut

package Jifty::Filter::DateTime;
use base qw(Jifty::DBI::Filter);

sub decode {
    my $self = shift;
    my $value_ref = $self->value_ref;

    return unless ref($$value_ref) && $$value_ref->isa('DateTime');

    # XXX There has to be a better way to do this
    my %args;
    for (qw(year month day hour minute second nanosecond)) {
        $args{$_} = $$value_ref->$_;
    }

    my $dt = Jifty::DateTime->new(%args);
    $dt->set_formatter($$value_ref->formatter);

    $$value_ref = $dt;
}

=head1 SEE ALSO

L<Jifty::DBI::Filter::Date>, L<Jifty::DBI::Filter::DateTime>,
L<Jifty::DateTime>

=cut

1;
