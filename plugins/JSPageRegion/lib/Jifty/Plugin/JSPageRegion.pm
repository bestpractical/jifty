use strict;
use warnings;

package Jifty::Plugin::JSPageRegion;
use base qw/Jifty::Plugin/;

use PadWalker;
use Jifty::Plugin::JSPageRegion::Compile;

Jifty->web->add_javascript(
    'template_declare.js',
    'jifty_jspageregion.js',
);

sub _actual_td_code {
    my $self = shift;
    my $path = shift;
    my $code = Template::Declare->resolve_template($path) or return;
    my $closed_over = PadWalker::closed_over($code)->{'$coderef'};
    return $closed_over ? $$closed_over : $code;
}


=head2 client_cacheable

Returns the type of cacheable object for client

=cut

sub client_cacheable {
    my ($self, $path) = @_;
    my $code = $self->_actual_td_code($path) or return;

    return 'static' if $Jifty::View::Declare::BaseClass::Static{$code};
    return 'action' if $Jifty::View::Declare::BaseClass::Action{$code};
    return;
}

=head2 compile_to_js

Compile the Template::Declare code of the given path to js.

=cut

sub compile_to_js {
    my ($self, $path) = @_;
    return Jifty::View::Declare::Compile->compile_to_js(
        $self->_actual_td_code($path)
    );
}

1;
