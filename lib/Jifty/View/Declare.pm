package Jifty::View::Declare;


use strict;
use warnings;
use constant BaseClass => 'Jifty::View::Declare::BaseClass';

=head1 SYNOPSIS

    package MyApp::View;
    use Jifty::View::Declare -base;

    template 'index.html' => page {
        { title is 'Some Title' }
        b { "The Index" };
    };

=cut

sub import {
    my ($class, $import) = @_;
    ($import and $import eq '-base') or return;
    no strict 'refs';
    my $pkg = caller;
    Jifty::Util->require(BaseClass);
    push @{ $pkg . '::ISA' }, BaseClass;

    @_ = BaseClass;
    goto &{BaseClass()->can('import')};
}

1;
