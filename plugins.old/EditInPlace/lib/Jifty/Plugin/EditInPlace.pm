use strict;
use warnings;

package Jifty::Plugin::EditInPlace;
use base qw/Jifty::Plugin/;


package HTML::Mason::Request::Jifty;

=head2 fetch_comp

=cut

sub fetch_comp {
    my $self = shift;
    my $comp = $self->SUPER::fetch_comp(@_);
    if (not $comp and  Jifty->config->framework('DevelMode') ) {
        my $comp_name = shift;
        $comp = $self->interp->make_component( 
                comp_source => 
                    "
                       <span id=\"create-component-$comp_name\">
<% Jifty->web->link(class => 'inline_create', label => 'Create $comp_name',  onclick => [ { element      => \"#create-component-$comp_name\", replace_with =>  '/__jifty/edit_inline/mason_component/$comp_name'  } ]) %>
                       </span> 
                    ");
            
            
    }
    return $comp;
}



1;
