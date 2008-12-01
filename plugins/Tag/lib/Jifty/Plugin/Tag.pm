use 5.008;
use utf8;
use strict;
use warnings;

package Jifty::Plugin::Tag;
use base qw/Jifty::Plugin/;

=head1 NAME

Jifty::Plugin::Tag - simple implementation of Tag model for Jifty apps

=head1 DESCRIPTION

This plugin in its early stage. You can try it at your own risk.

=head1 METHODS

=head2 init

Called during initialization.

=cut

sub init {
    my $self = shift;

    Jifty::DBI::Record->add_trigger(
        name     => "after_delete",
        callback => sub {
            my $record = shift;
            if (my $method = $record->can('delete_all_tags')) {
                $method->($record);
            }
        },
    );
}

=head1 AUTHOR

Ruslan Zakirov E<lt>Ruslan.Zakirov@gmail.comE<gt>

=cut

1;
