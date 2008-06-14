use strict;
use warnings;

package Jifty::Plugin::AdminUI;
use base qw/Jifty::Plugin/;


=head2 NAME

Jifty::Plugin::AdminUI - Add basic administrative CRUD view

=head2  DESCRIPTION

This plugin provides a basic administrative CRUD view for your application. It's included in every jifty application
by default.  While it's only accessible to the superuser, it's currently a bug that you can't disable it.

=cut


# Your plugin goes here.  If takes any configuration or arguments, you
# probably want to override L<Jifty::Plugin/init>.

1;
