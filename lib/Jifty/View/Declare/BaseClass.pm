package Jifty::View::Declare::BaseClass;

use strict;
use warnings;
use vars qw( $r );
use base qw/Jifty::View::Declare::Helpers/;
use Scalar::Defer;
use Template::Declare::Tags;
use Jifty::View::Declare::Helpers;

our @EXPORT = (
    @Jifty::View::Declare::Helpers::EXPORT,
    @Template::Declare::Tags::EXPORT,
    qw( page ),
);

{
    no warnings 'redefine';

    sub show {
        # Handle relative path here!

        my $path = shift;
        $path =~ s{^/}{};
        Jifty::View::Declare::Helpers->can('show')->( $path, @_ );
    }
}

# template 'foo' => page {{ title is 'Foo' } ... };
sub page (&) {
    my $code = shift;
    sub {
        Jifty->handler->apache->content_type('text/html; charset=utf-8');
        show('/_elements/nav');
        wrapper($code);
    };
}

1;
