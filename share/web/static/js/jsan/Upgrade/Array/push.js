/*
Upgrade.Array.push.VERSION = 0.04;
*/

// Provides Array.push for implementations that don't have it
if ( ! Array.prototype.push ) {
	Array.prototype.push = function () {
		var l = this.length;
		for ( var i = 0; i < arguments.length; i++ ) {
			this[l+i] = arguments[i];
		}
		return this.length;
	}
}
