var halo_shown = null;

var halo_top;
var halo_left;
var halo_width;

function halo_toggle (id) {
    if (halo_shown && (id != halo_shown)) {
        halo_top   = $('halo-'+halo_shown+'-menu').style.top;
        halo_left  = $('halo-'+halo_shown+'-menu').style.left;
        halo_width = $('halo-'+halo_shown+'-menu').style.width;
        Element.hide('halo-'+halo_shown+'-menu');
    }
    $('halo-'+id+'-menu').style.top   = halo_top;
    $('halo-'+id+'-menu').style.left  = halo_left;
    $('halo-'+id+'-menu').style.width = halo_width;
    Element.toggle('halo-'+id+'-menu');

    Drag.init( $('halo-'+id+'-title'), $('halo-'+id+'-menu') );
    init_resize($('halo-'+id+'-resize'), $('halo-'+id+'-menu') );

    var e = $('halo-'+id);
    if (Element.visible('halo-'+id+'-menu')) {
        halo_shown = id;
        Element.setStyle(e, {background: '#ffff80'});
    } else {
        halo_top   = $('halo-'+halo_shown+'-menu').style.top;
        halo_left  = $('halo-'+halo_shown+'-menu').style.left;
        halo_width = $('halo-'+halo_shown+'-menu').style.width;
        halo_shown = null;
        Element.setStyle(e, {background: 'inherit'});
    }

    return false;
}

function halo_over (id) {
    var e = $('halo-'+id);
    if (e) {
        Element.setStyle(e, {background: '#ffff80'});
    }
}

function halo_out (id) {
    var e = $('halo-'+id);
    if (e && ! Element.visible('halo-'+id+'-menu')) {
        Element.setStyle(e, {background: 'inherit'});
    }
}

function init_resize (e, w) {
    e.xFrom = e.yFrom = 0;
    Drag.init(e, null, null, null, null, null, true, true );
    e.onDrag = function(x, y) {
        resizeX( x, e, w );
    };
}

function resizeX (x, grip, window) {
    var width = parseInt( window.style.width );
    var newWidth = Math.abs( width - ( x - grip.xFrom ) ) + 'px';
    window.style.width = newWidth;
    grip.xFrom = x;
}
