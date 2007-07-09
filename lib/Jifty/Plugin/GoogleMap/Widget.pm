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
    my $self  = shift;

    my $action = $self->action;

    my ($x, $y) = map { $action->form_field($self->name . "_$_")->current_value } qw( x y );
    my ($xid, $yid) = map { $action->form_field($self->name . "_$_")->element_id } qw( x y );
    my $use_default = defined $x ? 0 : 1;
    ($x, $y) = (-71.2, 42.4) if $use_default;
    my $zoom_level = $use_default ? 1 : 13;

    Jifty->web->out(qq{<div @{[$self->_widget_class]} id="@{[$self->element_id]}" style="left: 200px; width: 200px; height: 200px"></div>});
    Jifty->web->out(qq{<script type="text/javascript">
(function() {
if (GBrowserIsCompatible()) {
         var map = new GMap2(document.getElementById("@{[$self->element_id]}"));
         map.enableScrollWheelZoom();
         map.addControl(new GSmallZoomControl());
         map.addControl(new EditLocationControl());
         map.setCenter(new GLatLng($y, $x), $zoom_level);
         map._jifty_form_x = "$xid";
         map._jifty_form_y = "$yid";
         if (!$use_default) {// XXX should be compile time
           map._jifty_location = new GMarker(new GLatLng($y, $x));
           map.addOverlay(map._jifty_location);
         }
GEvent.addListener(map, "click", function(marker, point) {
  if (!marker && map._jifty_edit_control.editing) {
    map.removeOverlay(map._jifty_location);
    map._jifty_location = new GMarker(point)
    map.addOverlay(map._jifty_location);
  }

});
      }
})()
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
    $_[0]->render_widget;
    return '';
}

1;
