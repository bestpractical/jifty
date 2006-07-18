use warnings;
use strict;

package Jifty::Param;

=head1 NAME

Jifty::Param - Parameters for Jifty actions

=head1 DESCRIPTION

=cut


use base qw/Jifty::Web::Form::Field/;
use Moose;
has constructor         => qw( is rw isa Bool ); # XXX - bad name
has valid_values        => qw( is rw isa Any );  # XXX - coercion
has available_values    => qw( is rw isa Any );  # XXX - coercion
has sort_order          => qw( is rw isa Int );
no Moose;

# Inhibit the reblessing inherent in Jifty::Web::Form::Field->BUILD
sub BUILDALL { 1; }

1;
