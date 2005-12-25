use warnings;
use strict;
 
package Jifty::Web::Form::Field::Password;

use base qw/Jifty::Web::Form::Field/;

=head2 type

The HTML input type is C<password>.

=cut

sub type { 'password' }

=head2 current_value

The default value of a password field should B<always> be empty.

=cut

sub current_value {''}

1;
