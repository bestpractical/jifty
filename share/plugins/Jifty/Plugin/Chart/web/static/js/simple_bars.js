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
    var dataset = $H();

    for (var i = 0; i < table.tBodies[0].rows.length; i++) {
        var table_row = table.tBodies[0].rows[i];
        dataset[table_row.cells[0].innerHTML] = table_row.cells[1].innerHTML;
    }

    var max_value = 0;
    dataset.values().each(function(v,i){max_value=Math.max(max_value, v);});

    var simple_bars = document.createElement('div');
    simple_bars.id = table.id;
    simple_bars.className = table.className;

    dataset.keys().each(function(k, i) {
        var v = dataset[k];

        var row = document.createElement('div');
        row.className = 'row';

        var row_label = document.createElement('span');
        row_label.className = 'label';
        row_label.innerHTML = k;
        row.appendChild(row_label);

        var row_bar_area = document.createElement('span');
        row_bar_area.className = 'barArea';
        row.appendChild(row_bar_area);

        var row_bar = document.createElement('span');
        row_bar.className = 'bar';
        row_bar.style.width = Math.round( 100 * v / max_value ) + '%';
        row_bar.innerHTML = '&nbsp;';
        row_bar_area.appendChild(row_bar);

        var row_value = document.createElement('span');
        row_value.className = 'value';
        row_value.innerHTML = v;
        row.appendChild(row_value);

        simple_bars.appendChild(row);
    });

    table.parentNode.insertBefore(simple_bars, table);
    table.parentNode.removeChild(table);

    return this;
}

Behaviour.register({
    'table.simple_bars': function(table) {
        new SimpleBars(table);
    }
});
