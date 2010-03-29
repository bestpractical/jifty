use warnings;
use strict;

package Jifty::YAML;

=head1 NAME

Jifty::YAML -- Wrapper around L<YAML>

=head1 DESCRIPTION

Provides a wrapper around the L<YAML> library.  If the faster L<YAML::Syck>
is available, then it's used instead.

=head1 METHODS

=head2 Dump

=head2 DumpFile

=head2 Load

=head2 LoadFile

Each of the above is alias to the equivalent function in either L<YAML>
or L<YAML::Syck>.

=cut

BEGIN {
    local $@;
    no strict 'refs';
    no warnings 'once';

    if ( eval { require YAML::Syck; YAML::Syck->VERSION(0.71) } ) {
        *Load     = *YAML::Syck::Load;


        require YAML;
        # Use YAML::Dump for the moment since YAML.pm segfaults on
        #  reading stupidly long (~20K characters) double-quoted
        #  strings, and we need to produce YAML.pm-readable output.
        *Dump     = *YAML::Dump;
        #*Dump     = *YAML::Syck::Dump;

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
