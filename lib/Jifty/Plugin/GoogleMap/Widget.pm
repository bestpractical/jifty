use warnings;
use strict;
 
package Jifty::Plugin::GoogleMap::Widget;

use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Plugin::GoogleMap::Widget - google map widget for geolocation display and editing

=head1 METHODS


=cut

sub accessors { shift->SUPER::accessors() };

=head2 render_widget

Renders form fields as googlemap widget.

=cut

# XXX: doesn't work
#use Template::Declare;
#use Template::Declare::Tags;

sub render_widget {
    my $self = shift;
    my $readonly = shift;
    my $action = $self->action;
    $readonly = $readonly ? 1 : 0;

    my ($x, $y) = map { $action->form_field($self->name . "_$_")->current_value } qw( x y );
    my ($xid, $yid) = map { $action->form_field($self->name . "_$_")->element_id } qw( x y );
    my $use_default = defined $x ? 0 : 1;
    ($x, $y) = (-71.2, 42.4) if $use_default;
    my $zoom_level = $use_default ? 1 : 13;
    my $element_id = $self->element_id;
    Jifty->web->out(qq{<div class="googlemap-widget-wrapper" style="left: 200px; width: 250px; height: 250px"><div @{[$self->_widget_class]} id="$element_id" style="left: 200px; width: 250px; height: 250px"></div>});
    Jifty->web->out(qq{<div class="googlemap-search-results" id="$element_id-result">FNORD</div></div>});
    Jifty->web->out(qq{<script type="text/javascript">
Jifty.GMap.location_editor( \$("$element_id"), $x, $y, "$xid", "$yid", $zoom_level, $use_default, $readonly);
</script>
});


    return '';
    Template::Declare->new_buffer_frame;

    div { { id is $self->element_id, style is "width: 200px; height: 200px" } };
    outs('hi');
    script { { type is "text/javascript" };
      qq{if (GBrowserIsCompatible()) {
         var map = new GMap2(document.getElementById("@{[$self->element_id]}"));
         map.setCenter(new GLatLng(37.4419, -122.1419), 13);
      }}
    };

warn "-----------_".Template::Declare->buffer->data;
    Jifty->web->out(Template::Declare->buffer->data);
    Template::Declare->end_buffer_frame;
    return '';
}

=head2 render_value

Renders value as a checkbox widget.

=cut

sub render_value {
    $_[0]->render_widget('readonly');
    return '';
}

1;
