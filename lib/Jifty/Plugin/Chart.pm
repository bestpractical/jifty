use strict;
use warnings;

package Jifty::Plugin::Chart;
use base qw/ Jifty::Plugin Class::Accessor::Fast /;

use Jifty::Plugin::Chart::Web;

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
        renderer: Jifty::Plugin::Chart::Renderer::Chart

=cut

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

=head1 SEE ALSO

L<Jifty::Plugin>, L<Jifty::Web>, L<Jifty::Plugin::Chart::Renderer>, L<Jifty::Plugin::Chart::Renderer::Chart>, L<Jifty::Plugin::Chart::View>

=head1 AUTHOR

Andrew Sterling Hanenkamp E<< <andrew.hanenkamp@boomer.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc.

This is free software and may be modified and redistributed under the same terms as Perl itself.

=cut

1;
