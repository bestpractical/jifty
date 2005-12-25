use warnings;
use strict;

package Jifty::Util;

=head1 NAME

Jifty::Util - Things that don't fit anywhere else

=head1 DESCRIPTION


=cut

use File::Spec;
use File::ShareDir;

=head2 absolute_path PATH

C<absolute_path> converts PATH into an absolute path, relative to the
application's root (as determined by L</app_root>)  This can be called
as an object or class method.

=cut

sub absolute_path {
    my $self = shift;
    my $path = shift;

    return File::Spec->rel2abs($path, Jifty::Util->app_root);
} 

=head2 jifty_root

Returns the root directory that Jifty has been installed into.
Uses %INC to figure out where Jifty.pm

=cut

sub jifty_root {
    my $self = shift;
    my ($vol,$dir,$file) = File::Spec->rel2abs($INC{"Jifty.pm"}); 
    return (File::Spec->rel2abs($dir));   
}

=head2 share_root

Returns the 'share' directory of the installed Jifty module.  This is
currently only used to store the common Mason components.

=cut

sub share_root {
    my $self = shift;
    my $dir =  File::Spec->rel2abs( File::ShareDir::module_dir('Jifty') );
    return $dir;
}

=head2 app_root

Returns the application's root path.  This is done by searching upward
from the current directory, looking for a directory which contains a
C<bin/jifty>.  Failing that, it searches upward from wherever the
executable was found.

It C<die>s if it can only find C</usr> or C</usr/local> which fit
these criteria.

=cut

sub app_root {
    require FindBin;
    require Cwd;

    my $cwd = Cwd::cwd();

    for ($cwd, $FindBin::Bin) {
        my @root = File::Spec->splitdir( $_ );
        while (@root) {
            my $try = File::Spec->catdir(@root, "bin", "jifty");
            if (-e $try and -x $try and $try ne "/usr/bin/jifty" and $try ne "/usr/local/bin/jifty") {
                return File::Spec->catdir(@root);
            }
            pop @root;
        }
    }

    die "Can't guess application root from current path ($cwd) or bin path ($FindBin::Bin)\n";
}

=head2 app_name

Returns the default name of the application.  This is the name of the
application's root directory, as defined by L</app_root>.

=cut

sub app_name {
    my $self = shift;
    my @root = File::Spec->splitdir( Jifty::Util->app_root);
    return pop @root;
}

=head1 AUTHOR

Various folks at BestPractical Solutions, LLC.

=cut

1;
