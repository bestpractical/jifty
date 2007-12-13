var cssQuery = function() {
    var cssQuery = function(a, c) {
        var q = jQuery.makeArray( jQuery(a,c) );
    }

    // All public interfaces are showing alert instead of doing the realthing.
    // Deep compatibiliy isn't going to be implemented.
    cssQuery.toString = cssQuery.clearCache = cssQuery.addModule = cssQuery.valueOf = function() {
        var msg = "This implementation of cssQuery is really a wrapper to jQuery. No compatibility is ensured. Please use jQuery instead.";
        alert(msg);
    };

    return cssQuery;

}();
