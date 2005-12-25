use warnings;
use strict;
 
package JFDI::Web::Form::Field::InlineButton;

use base qw/JFDI::Web::Form::Field::Button/;


=head2 render

Overrides the default render sub to print a span, not a div and not print labels and preambles and hints

XXX TODO the superclass should be more general, so we can just override those things to not print

=cut

sub render_wrapper_start { }
sub render_wrapper_end {}
sub render_label {}

1;
