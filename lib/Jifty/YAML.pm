use warnings;
use strict;

package Jifty::YAML;

=head1 NAME

Jifty::YAML -- Wrapper around L<YAML>

=head1 DESCRIPTION

Provides a wrapper around the L<YAML> library.  If the faster L<YAML::Syck>
is available, then it's used instead.

=cut

BEGIN {
    local $@;
    no strict 'refs';
    no warnings 'once';

    if ( eval { require YAML::Syck; $YAML::Syck::VERSION >= 0.27 } ) {
        *Load     = *YAML::Syck::Load;

        # XXX Force non-Syck Dump until it can handle dumping circular
        # references, which show up in halos while dumping component
        # arguments
        require YAML;
        *Dump     = *YAML::Dump;

        *LoadFile = *YAML::Syck::LoadFile;
        *DumpFile = *YAML::Syck::DumpFile;
    } else {
        require YAML;
        *Load     = *YAML::Load;
        *Dump     = *YAML::Dump;
        *LoadFile = *YAML::LoadFile;
        *DumpFile = *YAML::DumpFile;
    }
}

1;
