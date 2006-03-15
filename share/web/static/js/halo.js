
function halo_toggle (id) {
    Element.toggle('halo-'+id+'-menu');
    var e = $('halo-'+id);
//    new Draggable( $('halo-'+id+'-menu'), {starteffect: null, endeffect: null} );
    Drag.init( $('halo-'+id+'-menu') );
    return false;
}

var halo_effects = {};

function halo_over (id) {
    var e = $('halo-'+id);
    if (e) {
        Element.setStyle(e, {background: '#ffff80'});
    }
}

function halo_out (id) {
    var e = $('halo-'+id);
    if (e) {
        Element.setStyle(e, {background: 'inherit'});
    }
}
