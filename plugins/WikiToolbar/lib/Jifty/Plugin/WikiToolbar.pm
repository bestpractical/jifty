use strict;
use warnings;

package Jifty::Plugin::WikiToolbar;
use base qw/Jifty::Plugin/;

=head1 SYNOPSIS

In etc/config.yml

   Plugins:
     - WikiToolbar: {}

In your Model instead of 

   render_as 'textarea';

use

  render_as 'Jifty::Plugin::WikiToolbar::Textarea';

To custom the toolbar, copy wikitoolbar.js in your application, at the end of the file put your changes with addButton function.

=head1 DESCRIPTION

Add a toolbar to your textarea field. Default toolbar provide markdown markup syntax. http://daringfireball.net/projects/markdown/

=cut

sub init {
    my $self = shift;
    Jifty->web->javascript_libs([
    @{ Jifty->web->javascript_libs },
    "wikitoolbar.js",
    ]);
}

1;
