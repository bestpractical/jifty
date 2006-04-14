#line 1
package Module::Install::Share;

BEGIN {
	$VERSION = '0.61';
	@ISA     = qw{Module::Install::Base};
}

use strict;
use Module::Install::Base;

sub install_share {
    my ($self, $dir) = @_;

    if ( ! defined $dir ) {
        die "Cannot find the 'share' directory" unless -d 'share';
        $dir = 'share';
    }

    $self->postamble(<<"END_MAKEFILE");
config ::
\t\$(NOECHO) \$(MOD_INSTALL) \\
\t\t\"$dir\" \$(INST_AUTODIR)

END_MAKEFILE
}

1;

__END__

#line 90
