/*
	IE7, version 0.9 (alpha) (2005-08-19)
	Copyright: 2004-2005, Dean Edwards (http://dean.edwards.name/)
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/

if (appVersion < 5.5) {

/* ---------------------------------------------------------------------
  This module is loaded automatically by IE7.
--------------------------------------------------------------------- */

	ANON = "HTML:!"; // for anonymous content

	var $$apply = function($function, $object, $arguments) {
		$function.apply($object, $arguments);
	};

	// fix String.replace
	if (''.replace(/^/, String)) {
		// preserve String.replace
		var _stringReplace = String.prototype.replace;
		// create String.replace for handling functions
		var _functionReplace = function($expression, $replacement) {
			var $match, $newString = "", $string = this;
			while ($string && ($match = $expression.exec($string))) {
				$newString += $string.slice(0, $match.index) + $$apply($replacement, this, $match);
				$string = $string.slice($match.lastIndex);
			}
			return $newString + $string;
		};
		// replace String.replace
		String.prototype.replace = function ($expression, $replacement) {
			this.replace = (typeof $replacement == "function") ? _functionReplace : _stringReplace;
			return this.replace($expression, $replacement);
		};
	}

	// fix Function.apply
	if (!Function.apply) {
		var APPLY = "apply-" + Number(new Date);
		$$apply = function(f, o, a) {
			var r;
			o[APPLY] = f;
			switch (a.length) { // deconstruct for speed
				case 0: r = o[APPLY](); break;
				case 1: r = o[APPLY](a[0]); break;
				case 2: r = o[APPLY](a[0], a[1]); break;
				case 3: r = o[APPLY](a[0], a[1], a[2]); break;
				case 4: r = o[APPLY](a[0], a[1], a[2], a[3]); break;
				default:
					var aa = [], i = a.length - 1;
					do aa[i] = "a[" + i + "]"; while (i--);
					eval("r=o[APPLY](" + aa + ")");
			}
			delete o[APPLY];
			return r;
		};
		// fix ICommon
		ICommon.valueOf.prototype.inherit = function() {
			return $$apply(arguments.callee.caller.ancestor, this, arguments);
		};
	}

	// array fixes
	if (![].push) Array.prototype.push = function() {
		for (var i = 0; i < arguments.length; i++) {
			this[this.length] = arguments[i];
		}
		return this.length;
	};
	if (![].pop) Array.prototype.pop = function() {
		var $item = this[this.length - 1];
		this.length--;
		return $item;
	};

	// block elements are "inline" according to IE5.0 so we'll fix it
	if (isHTML) {
		HEADER += "address,blockquote,body,dd,div,dt,fieldset,form,"+
		"frame,frameset,h1,h2,h3,h4,h5,h6,iframe,noframes,object,p,"+
		"hr,applet,center,dir,menu,pre,dl,li,ol,ul{display:block}";
	}
}
