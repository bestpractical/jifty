use warnings;
use strict;

=head1 NAME

Jifty::Record::Versioned -- Revision-controlled database records for Jifty

=head1 SYNOPSIS

In your F<etc/config.yml>:

  framework:
    Database:
      RecordBaseClass: Jifty::Record::Versioned

=cut

package Jifty::Record::Versioned;
use Jifty::Util;
use Jifty::Record;
use base 'Jifty::DBI::Record';

sub __create {
    my ($self, %attribs) = @_;
    my $uuid = ($attribs{__uuid} ||= Jifty::Util->generate_uuid);
    my $rv = $self->SUPER::__create(%attribs);
    if ($rv) {
        # Write to SQL!
        # print YAML::Syck::Dump(\%attribs);
    }
    return $rv;
}

sub __set {
    my $self = shift;
    return $self->SUPER::__set(@_);
}

sub __delete {
    my $self = shift;
    return $self->SUPER::__set(@_);
}

1;
