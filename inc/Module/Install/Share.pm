#line 1 "inc/Module/Install/Share.pm - /usr/lib/perl5/site_perl/5.8.7/Module/Install/Share.pm"
package Module::Install::Share;

use Module::Install::Base;
@ISA = qw(Module::Install::Base);

$VERSION = '0.02';

use strict;

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

#line 65
