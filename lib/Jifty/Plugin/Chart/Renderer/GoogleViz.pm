package Jifty::Plugin::Chart::Renderer::GoogleViz;
use strict;
use warnings;
use base 'Jifty::Plugin::Chart::Renderer';

=head2 init

We need to load Google's JS.

=cut

sub init {
    my $self = shift;

    Jifty->web->add_external_javascript("http://www.google.com/jsapi");
}

=head2 render

=cut

sub render {
    my $self = shift;
    if (ref($self) eq __PACKAGE) {
        Carp::croak("You must use a subclass of GoogleViz, such as GoogleViz::AnnotatedTimeLine");
    }
    else {
        Carp::croak(ref($self) . " does not implement render.");
    }
}

1;

