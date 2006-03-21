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


=head2 other_widget_properties

No completion in password fields ;)

=cut

sub other_widget_properties {
    return q{autocomplete="off"};
}

=head2 render_value 

Never render a value for a password

=cut


sub render_value {
    return '-';
}

sub classes {
    my $self = shift;
    return join(' ', 'password', ($self->SUPER::classes));
}

1;
