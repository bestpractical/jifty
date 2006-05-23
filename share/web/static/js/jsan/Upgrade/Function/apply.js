/*
Upgrade.Function.Apply.VERSION = 0.04;
*/
// Adapted from a Prototype adaptation of code
// originally from http://www.youngpup.net/
if ( ! Function.prototype.apply ) {
	Function.prototype.apply = function(o, p) {
		var pstr = new Array();
		if ( ! o ) o = window;
		if ( ! p ) p = new Array();
		for ( var i = 0; i < p.length; i++ ) {
			pstr[i] = 'p[' + i + ']';
		}
    		o.__apply__ = this;
		var rv = eval('o.__apply__(' + pstr[i].join(', ') + ')' );
		o.__apply__ = null;
		return rv;
	}
}
