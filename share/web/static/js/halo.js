var halo_shown = null;
var halos_drawn = null;

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

function draw_halos() {
    var halo_header_display = 'none';
    var halo_border_width   = '0';
    var halo_margin         = '0';

    halos_drawn = !halos_drawn;

    if (halos_drawn) {
        halo_header_display = 'block';
        halo_border_width   = '1px';
        halo_margin         = '2px';
    }

    YAHOO.util.Dom.getElementsByClassName("halo_header", null, null,
        function (e) {
            e.style.display = halo_header_display;
        }
    );

    YAHOO.util.Dom.getElementsByClassName("halo", null, null,
        function (e) {
            e.style.borderWidth = halo_border_width;
            e.style.margin = halo_margin;
        }
    );
}

function render_info_tree() {
    Element.toggle("render_info_tree");
}

function halo_render(id) {
    $('halo-render-'+id).style.fontWeight = 'bold';
    $('halo-source-'+id).style.fontWeight = 'normal';

    var e = $('halo-inner-'+id);
    if (e.halo_rendered) {
        e.innerHTML = e.halo_rendered;
        e.halo_rendered = null;
    }
}

function halo_source(id) {
    $('halo-source-'+id).style.fontWeight = 'bold';
    $('halo-render-'+id).style.fontWeight = 'normal';

    var e = $('halo-inner-'+id);
    if (!e.halo_rendered) {
        e.halo_rendered = e.innerHTML;
        e.innerHTML = '<div class="halo_source">' + e.innerHTML.escapeHTML() + '</div>';
    }
}

