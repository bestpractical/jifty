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

1;
