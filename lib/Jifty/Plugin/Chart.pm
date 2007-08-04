use strict;
use warnings;

package Jifty::Plugin::Chart;
use base qw/ Jifty::Plugin Class::Accessor::Fast /;

use Jifty::Plugin::Chart::Web;
use Scalar::Util qw/ blessed /;

__PACKAGE__->mk_accessors(qw/ renderer renderers /);

=head1 NAME

Jifty::Plugin::Chart - A charting API for Jifty

=head1 SYNOPSIS

In your F<config.yml>:

  Plugins:
    - Chart: {}

In your Mason templates:

  <% Jifty->web->chart(
      type   => 'Bar',
      width  => 400,
      height => 300,
      data   => [
          [ '2004', '2005', '2006', '2007' ], # labels
          [ 14,     15,     17,     22     ], # first data set
          [ 22,     25,     20,     21     ], # second data set
      ],
  ) %>

=head1 DESCRIPTION

B<CAUTION:> This plugin is experimental. The API I<will> change.

This plugin provides a charting API that can be used by Jifty applications to build data visualizations without regard to the underlying rendering mechanism.

As of this writing, the API is a barely veiled interface over L<Chart>. However, I intend to expand the interface to apply to something like Maani's XML/SWF Charts or Imprise Javascript charts or even something like OpenLaszlo (or something Open Source and Perl if I can find or build such a thing in time).

=head1 INTERFACE

By adding this method to the plugin configuration for your Jifty application, you will cause L<Jifty::Web> to inherit a new method, C<chart>, which is the cornerstone of this API.

This method is described in L<Jifty::Plugin::Chart::Web> and an example is shown in the L</SYNOPSIS> above.

=head1 CONFIGURATION

The plugin takes a single configuration option called C<renderer>. This may be set to a chart renderer class, which is just an implementation of L<Jifty::Plugin::Chart::Renderer>. The default, L<Jifty::Plugin::Chart::Renderer::Chart>, uses L<Chart> to render charts as PNG files which are then included in your pages for you.

Here is an example configuration for F<config.yml>:

  Plugins:
    - Chart:
        renderer: Chart

=head1 METHODS

=head2 init

Adds the L<Jifty::Plugin::Chart::Web/chart> method to L<Jifty::Web>.

=cut

sub init {
    my $self = shift;
    my %args = (
        renderer => 'Chart',
        @_,
    );

    # Create the empty renderers list
    $self->renderers({});

    # Load the default renderer
    $self->renderer( $self->init_renderer($args{renderer}) );

    push @Jifty::Web::ISA, 'Jifty::Plugin::Chart::Web';
}

=head2 init_renderer

  my $renderer = $chart_plugin->init_renderer($renderer_class)

This is a helper method that is used by the API to initialize the renderer class. This is handled automatically so you probably shouldn't use this.

=cut

sub init_renderer {
    my ($self, $renderer_class) = @_;

    # If it's already an object, just return that
    if ( blessed($renderer_class)
            and $renderer_class->isa(__PACKAGE__.'::Renderer') ) {
        return $renderer_class;
    }

    # Prepend Jifty::Plugin::Chart::Renderer:: if we think we need to
    if ( $renderer_class !~ /::/ ) {
        $renderer_class = __PACKAGE__.'::Renderer::'.$renderer_class;
    }

    # Check to see if we already loaded this one
    my $renderer = $self->renderers->{ $renderer_class };
    return $renderer if defined $renderer;

    # Tell perl to load the class
    $renderer_class->require
        or warn $@;

    # Initialize the renderer
    $renderer = $renderer_class->new;

    # Remember it
    $self->renderers->{ $renderer_class } = $renderer;

    # Return it!
    return $renderer;
}

=head1 SEE ALSO

L<Jifty::Plugin>, L<Jifty::Web>, L<Jifty::Plugin::Chart::Renderer>, L<Jifty::Plugin::Chart::Renderer::Chart>, L<Jifty::Plugin::Chart::View>

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <andrew.hanenkamp@boomer.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc.

This is free software and may be modified and redistributed under the same terms as Perl itself.

=cut

1;
