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
    var halo_padding        = '0';

    halos_drawn = !halos_drawn;

    if (halos_drawn) {
        halo_header_display = 'block';
        halo_border_width   = '2px';
        halo_margin         = '3px';
        halo_padding        = '3px';
    }

    $("render_info-draw_halos").innerHTML = halos_drawn ? "Hide halos" : "Draw halos";

    YAHOO.util.Dom.getElementsByClassName("halo-header", null, null,
        function (e) {
            e.style.display = halo_header_display;
        }
    );

    YAHOO.util.Dom.getElementsByClassName("halo", null, null,
        function (e) {
            e.style.borderWidth = halo_border_width;
            e.style.margin = halo_margin;
            e.style.padding = halo_padding;
        }
    );
}

function render_info_tree() {
    jQuery("#render_info_tree").toggle();
}

function halo_render(id, name) {
    halo_reset(id);
    $('halo-button-'+name+'-'+id).style.fontWeight = 'bold';

    var e = $('halo-rendered-'+id);

    if (name == 'source') {
        e.halo_rendered = e.innerHTML;
        e.innerHTML = '<div class="halo-source">' + e.innerHTML.escapeHTML() + '</div>';
    }
    else if (name == 'render') {
        /* ignore */
    }
    else {
        e.style.display = 'none';
        $('halo-info-'+id).style.display = 'block';
        $('halo-info-'+name+'-'+id).style.display = 'block';
    }
}

function halo_reset(id) {
    /* restore all buttons to nonbold */
    for (var child = $('halo-rendermode-'+id).firstChild;
         child != null;
         child = child.nextSibling) {
            if (child.style) {
                child.style.fontWeight = 'normal';
            }
    }

    /* hide all the info divs */
    $('halo-info-'+id).style.display = 'none';
    for (var child = $('halo-info-'+id).firstChild;
         child != null;
         child = child.nextSibling) {
            if (child.style) {
                child.style.display = 'none';
            }
    }

    /* restore the rendered div */
    var e = $('halo-rendered-'+id);
    e.style.display = 'block';
    if (e.halo_rendered) {
        e.innerHTML = e.halo_rendered;
        e.halo_rendered = null;
    }
}

function remove_link(id, name) {
    var link = $('halo-button-'+name+'-'+id);
    var newlink = document.createElement("span");
    newlink.appendChild(link.childNodes[0]);
    link.parentNode.replaceChild(newlink, link);
}

