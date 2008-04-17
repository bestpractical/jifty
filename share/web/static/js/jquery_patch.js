/**
 * jquery_patch.js - patch jQuery in the right manner
 */
jQuery.extend({
	globalEval: function( data ) {
		data = jQuery.trim( data );

		if ( data ) {
			// Inspired by code by Andrea Giammarchi
			// http://webreflection.blogspot.com/2007/08/global-scope-evaluation-and-dom.html
			var head = document.getElementsByTagName("head")[0] || document.documentElement,
				script = document.createElement("script");

			script.type = "text/javascript";
			if ( jQuery.browser.msie ) {
				script.text = data;
            }
			else
				script.appendChild( document.createTextNode( data ) );

			head.appendChild( script );
            try {
                head.removeChild( script );
            } catch( error ) {
                setTimeout( function() {
                    var head = document.getElementsByTagName("head")[0] || document.documentElement;
                    head.removeChild( script );
                }, 0);
            }
		}
	}
});
