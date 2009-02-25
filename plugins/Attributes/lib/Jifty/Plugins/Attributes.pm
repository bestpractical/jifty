use strict;
use warnings;

package Jifty::Plugin::Attributes;
use base 'Jifty::Plugin';

our $VERSION = '0.01';

=head1 NAME

Jifty::Plugin::Attributes - Associate arbitrary key-value attributes with any Jifty record

=cut

sub init {
    Jifty::DBI::Record->add_trigger(
        name      => "after_delete",
        callback  => sub {
            my $record = shift;
            if ($record->can('delete_all_attributes')) {
                $record->delete_all_attributes;
            }
        },
    );
}

1;

