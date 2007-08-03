/*
 * chart_behaviour.js
 *
 * Helper to make charts more designer friendly.
 */

Behaviour.register({
    'img.chart': function(e) {
        var dim = Element.getDimensions(e);
        var url = e.src;
        url += url.indexOf('?') >= 0 ? '&' : '?';
        url += 'width=' + dim.width + 'px';
        url += '&height=' + dim.height + 'px';
        e.src = url;
    },
});
