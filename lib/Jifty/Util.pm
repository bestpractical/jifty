use warnings;
use strict;

package Jifty::Util;

=head1 NAME

Jifty::Util - Things that don't fit anywhere else

=head1 DESCRIPTION


=cut

use File::Spec;

=head2 absolute_path PATH

C<absolute_path> converts PATH into an absolute path, relative to the
parent of the parent of the executable.  (This assumes that the
executable is in C<I<ApplicationRoot>/bin/>.)  This can be called as
an object or class method.

=cut

sub absolute_path {
    my $self = shift;
    my $path = shift;

    my @root = File::Spec->splitdir( File::Spec->rel2abs($0));
    pop @root; # filename
    pop @root; # bin
    my $root = File::Spec->catdir(@root);
    
    return File::Spec->rel2abs($path, $root);
} 


=head1 AUTHOR

Various folks at BestPractical Solutions, LLC.

=cut

1;
