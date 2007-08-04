/*
 * chart_behaviour.js
 *
 * Helper to make charts more designer friendly.
 */

Behaviour.register({
    'img.chart': function(e) {
        var dim = Element.getDimensions(e);
        var url = e.src;

        var path  = url;
        var query = $H();

        if (url.indexOf('?') >= 0) {
            var path_and_query = url.split('?');
            path = path_and_query[0];

            var query_params = path_and_query[1].split('&');
            for (var query_param in query_params) {
                var key_and_value = query_param.split('=');
                query[ key_and_value[0] ] = key_and_value[1];
            }
        }

        query['width']  = dim.width + 'px';
        query['height'] = dim.height + 'px';

        url = path + '?' + query.toQueryString();

        e.src = url;
    },
});
