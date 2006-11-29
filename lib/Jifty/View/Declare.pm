package Jifty::View::Declare;
use Jifty::View::Declare::Base ();

use strict;
use warnings;
use constant BaseClass => 'Jifty::View::Declare::Base';

=head1 SYNOPSIS

    package MyApp::View;
    use Jifty::View::Declare -base;

    template 'index.html' => page {
        b { "The Index" };
    } 'Some Title';

=cut

sub import {
    my ($class, $import) = @_;
    ($import and $import eq '-base') or return;

    no strict 'refs';
    my $pkg = caller;
    push @{ $pkg . '::ISA' }, BaseClass;

    @_ = BaseClass;
    goto &{BaseClass()->can('import')};
}

1;
