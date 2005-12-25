use warnings;
use strict;
 
package JFDI::Web::Form::Field::Date;

use base qw/JFDI::Web::Form::Field/;


=head2 render_widget

Output the basic edit widget and some javascript to pop up a calendar

=cut

sub render_widget {
    my $self  = shift;
    $self->SUPER::render_widget();

    JFDI->mason->out( <<"EOF");
    <script language="JavaScript">
    <!--
document.write('<a href="#" onClick="openCalWindow(' + "'@{[$self->input_name]}'" +')\">Calendar</a>');
    //-->
    </script>
EOF
    
    return '';
}

1;
