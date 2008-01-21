/*
 * $Id$
 * simple_bars.js
 * by Andrew Sterling Hanenkamp
 *
 * Copyright 2007 Boomer Consulting, Inc.
 *
 * A custom and extremely simple way of rendering a horizontal bar chart. This
 * code was custom built for use with Jifty, but could be reused elsewhere.
 *
 * This is free software. You may modify or redistribute this code under the
 * terms of the GNU General Public License or the Artistic license.
 */

function SimpleBars(table) {
    var dataSet = {};

    jQuery('tr', table).each(function() {
        dataSet[ jQuery(this.cells[0]).text() ] = jQuery(this.cells[1]).text();
    });

    var maxValue = 0;
    for (var name in dataSet) {
        maxValue = Math.max(maxValue, dataSet[name]);
    }

    var simpleBars 
        = jQuery("<div/>")
            .attr('id', table.attr('id'))
            .attr('class', table.attr('class'));

    for (var k in dataSet) {
        var v = dataSet[k];

        var row = jQuery('<div class="row"/>');
        jQuery('<span class="label"/>')
            .text(k)
            .appendTo(row);

        var rowBarArea = jQuery('<span class="barArea"/>');
        jQuery('<span class="bar"/>')
            .css('width', Math.round( 100 * v / maxValue ) + '%')
            .html('&nbsp;')
            .appendTo(rowBarArea);
        rowBarArea.appendTo(row);

        jQuery('<span class="value"/>')
            .text(v)
            .appendTo(row);

        simpleBars.append(row);
    }

    table.before(simpleBars);
    table.remove();

    return this;
}

Behaviour.register({
    'table.simple_bars': function(table) {
        new SimpleBars(jQuery(table));
    }
});
