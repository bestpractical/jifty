use warnings;
use strict;
 
package Jifty::Web::Form::Field::Password;

use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Web::Form::Field::Password - Add a password field to your forms

=head1 METHODS

=head2 type

The HTML input type is C<password>.

=cut

sub type { 'password' }

=head2 current_value

The default value of a password field should B<always> be empty.

=cut

sub current_value {''}

=head2 other_widget_properties

No browser-based form auto-completion in password fields ;)

Note: This has nothing to do with Jifty's Autocomplete mechanism.

=cut

sub other_widget_properties {
    return q{autocomplete="off"};
}

=head2 render_value 

Never render a value for a password

=cut


sub render_value {
    Jifty->web->out('-');
    return '';
}

=head2 classes

Output password fields with the class 'password'

=cut

sub classes {
    my $self = shift;
    return join(' ', 'password', ($self->SUPER::classes));
}

1;
