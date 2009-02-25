use strict;
use warnings;

package Jifty::Plugin::ProfileBehaviour;
use base qw/Jifty::Plugin/;

=head1 NAME

Jifty::Plugin::ProfileBehaviour - Overrides behavior.js to add profiling information

=head1 DESCRIPTION

This plugin overrides the stock behavior.js library to add timing and
profiling information.  Add it if your web pages are slow to style,
and you want to track down which rules are causing the slowness.

=head1 METHODS

=head2 init

Adds the CSS file needed for on-screen profiling.

=cut

sub init {
    Jifty->web->add_css('behavior-profile.css');
}

1;
