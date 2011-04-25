use strict;
use warnings;

package Jifty::Plugin::RequestInspector::Model::Request;

use base qw( Jifty::Record );

use Jifty::DBI::Schema;
use Jifty::Record schema {

column data => type is 'blob',
  filters are 'Jifty::DBI::Filter::Storable';

};

sub since { '0.0.2' }

1;

__END__

=head1 NAME

Jifty::Plugin::RequestInspector::Model::Request - Persistent storage for the request inspector

=head1 METHODS

=head2 since

This model has existed since version 0.0.2 of the RequestInspector
plugin.

=cut
