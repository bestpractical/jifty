use strict;
use warnings;

package Jifty::Plugin::Chart::View;
use Jifty::View::Declare -base;

use IO::String;

template 'chart' => sub {
    my $args = get 'args';

    my $class = 'Chart::' . $args->{type};

    eval "use $class";
    die $@ if $@;

    Jifty->handler->apache->content_type('image/png');

    my $fh = IO::String->new;
    my $chart = $class->new( $args->{width}, $args->{height} );
    $chart->png($fh, $args->{data});
    outs_raw( ${ $fh->string_ref } )
};

1;
