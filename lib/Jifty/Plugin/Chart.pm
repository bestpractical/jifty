use strict;
use warnings;

package Jifty::Plugin::Chart;
use base qw/ Jifty::Plugin Class::Accessor::Fast /;

use Jifty::Plugin::Chart::Web;

__PACKAGE__->mk_accessors(qw/ renderer /);

sub init {
    my $self = shift;
    my %args = (
        renderer => __PACKAGE__.'::Renderer::Chart',
        @_,
    );

    eval "use $args{renderer}";
    warn $@ if $@;
    $self->renderer( $args{renderer} );

    push @Jifty::Web::ISA, 'Jifty::Plugin::Chart::Web';
}

sub render {
    my $self = shift;
    $self->renderer->render(@_);
}

1;
