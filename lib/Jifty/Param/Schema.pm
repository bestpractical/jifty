package Jifty::Param::Schema;

use Jifty::I18N;
use Jifty::Param;
use Scalar::Defer;
use Object::Declare ['Jifty::Param'];
use Exporter::Lite;
use Class::Data::Inheritable;

our @EXPORT = qw( defer lazy param schema from );

sub schema (&) {
    my $code = shift;
    my $from = caller;

    no warnings 'redefine';
    local *_ = sub {
        my $args = \@_;
        defer { local *_; Jifty::I18N->new; _(@$args) };
    };

    Class::Data::Inheritable::mk_classdata($from => qw/PARAMS/);
    my @params = &declare($code);
    my $count = 100; # arbitrary number
    foreach my $param (@params) {
        $param->sort_order($count++) if ref($param) and !defined($param->sort_order);
    }
    $from->PARAMS({ @params });

    no strict 'refs';
    push @{$from . '::ISA'}, 'Jifty::Action';
    return;
}

1;
