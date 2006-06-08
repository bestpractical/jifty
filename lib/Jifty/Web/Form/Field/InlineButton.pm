use warnings;
use strict;
 
package Jifty::Web::Form::Field::InlineButton;

use base qw/Jifty::Web::Form::Field::Button/;


=head2 render

Overrides the default render sub to print a span, not a div and not print labels and preambles and hints

XXX TODO the superclass should be more general, so we can just override those things to not print

=cut

=head2 render_wrapper_start

Don't show a wrapper for an inline button

=head2 render_wrapper_end

Don't show a wrapper for an inline button

=head2 render_label

Don't show a label for an inline button

=head2 render_hints

Don't show hints for an inline button

=cut



sub render_wrapper_start { }
sub render_wrapper_end {}
sub render_label {}
sub render_hints {}

1;
