var halo_shown = null;
var halos_drawn = null;

var halo_top;
var halo_left;
var halo_width;

function halo_toggle (id) {
    if (halo_shown && (id != halo_shown)) {
        halo_top   = Jifty.$('halo-'+halo_shown+'-menu').style.top;
        halo_left  = Jifty.$('halo-'+halo_shown+'-menu').style.left;
        halo_width = Jifty.$('halo-'+halo_shown+'-menu').style.width;
        jQuery('halo-'+halo_shown+'-menu').hide();
    }

    jQuery("#halo-"+id+"-menu").css({
        top: halo_top,
        left: halo_left,
        width: halo_width
    }).toggle();

    Drag.init( $('halo-'+id+'-title'), $('halo-'+id+'-menu') );
    init_resize($('halo-'+id+'-resize'), $('halo-'+id+'-menu') );

    var e = $('halo-'+id);
    if (jQuery('#halo-'+id+'-menu').is(":visible")) {
        halo_shown = id;
        jQuery(e).css({ background: '#ffff80' });
    } else {
        halo_top   = $('halo-'+halo_shown+'-menu').style.top;
        halo_left  = $('halo-'+halo_shown+'-menu').style.left;
        halo_width = $('halo-'+halo_shown+'-menu').style.width;
        halo_shown = null;
        jQuery(e).css({ background: 'inherit' });
    }

    return false;
}

function halo_over (id) {
    jQuery('#halo-'+id).css({ background: '#ffff80' });
}

function halo_out (id) {
    if (! jQuery("#halo-"+id+"-menu").is(":visible")) {
        jQuery('#halo-'+id).css({ background: 'inherit' });
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

    jQuery(".halo_header").css({
        display: halo_header_display
    });

    jQuery(".halo").css({
        'border-width': halo_border_width,
        'margin': halo_margin
    });
}

function render_info_tree() {
    jQuery("#render_info_tree").toggle();
}

function halo_render(id) {
    halo_reset(id);
    jQuery('#halo-button-render-'+id).css({ 'font-weight': 'bold' });

    var e = Jifty.$('halo-inner-'+id);
    if (e.halo_rendered) {
        e.innerHTML = e.halo_rendered;
        e.halo_rendered = null;
    }
}

function halo_source(id) {
    halo_reset(id);
    Jifty.$('halo-button-source-'+id).style.fontWeight = 'bold';

    var e = Jifty.$('halo-inner-'+id);
    if (!e.halo_rendered) {
        e.halo_rendered = e.innerHTML;
        jQuery(e).empty().append( jQuery('<div class="halo_source"></div>').text(e.halo_rendered) );
    }
}

function halo_perl(id) {
    halo_reset(id);
    Jifty.$('halo-button-perl-'+id).style.fontWeight = 'bold';
    Jifty.$('halo-inner-'+id).style.display   = 'none';
    Jifty.$('halo-perl-'+id).style.display    = 'block';
}

function halo_reset(id) {
    jQuery.each([
            "button-perl", "button-source", "button-render", "inner", "perl"
    ], function() {
        jQuery("#halo-" + this + "-" + id).css({ 'font-weight': 'normal' });
    });
}

