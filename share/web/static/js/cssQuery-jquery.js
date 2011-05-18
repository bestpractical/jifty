var cssQuery = function() {
    var cssQuery = function(a, c) {
        return jQuery.makeArray( jQuery(a,c) );
    }

    // All public interfaces are showing alert instead of doing the realthing.
    // Deep compatibiliy isn't going to be implemented.
    var msg = "This implementation of cssQuery is really a wrapper to jQuery. No compatibility is ensured. Please use jQuery instead.";
    var warned = 0;
    cssQuery.toString = function() {
        return "function() { [" + msg +  "] }";
    };

     cssQuery.clearCache = cssQuery.addModule = cssQuery.valueOf = function() {
        if (warned) return;
        ++warned;
        alert(msg);
    };

    return cssQuery;

}();
