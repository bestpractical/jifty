use warnings;
use strict;
 
package Jifty::Web::Form::Field::Date;

use base qw/Jifty::Web::Form::Field/;


=head2 render_widget

Output the basic edit widget and some javascript to pop up a calendar

=cut

sub render_widget {
    my $self  = shift;
    $self->length(12);
    $self->SUPER::render_widget();

    Jifty->web->mason->out( <<"EOF");
    <script type="text/javascript"><!--
        onLoadHook('createCalendarLink("@{[$self->input_name]}")');
    --></script>
EOF
    
    return '';
}

1;
