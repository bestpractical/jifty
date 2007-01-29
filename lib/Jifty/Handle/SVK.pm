use warnings;
use strict;

package Jifty::Handle::SVK;
use base 'Jifty::Handle';

=head1 NAME

Jifty::Handle::SVK -- Revision-controlled database handles for Jifty

=head1 SYNOPSIS

In your F<etc/config.yml>:

  framework:
    Database:
      HandleClass: Jifty::Handle::SVK

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}

1;
