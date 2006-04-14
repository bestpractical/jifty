/**
  * THIS VERSION OF IE7 HAS BEEN SLIGHTLY MODIFIED.  See "XXX TODO" below.
  */

/*
	IE7, version 0.9 (alpha) (2005-08-19)
	Copyright: 2004-2005, Dean Edwards (http://dean.edwards.name/)
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/

/* W3C compliance for Microsoft Internet Explorer */

/* credits/thanks:
	Shaggy, Martijn Wargers, Jimmy Cerra, Mark D Anderson,
	Lars Dieckow, Erik Arvidsson, Gellért Gyuris, James Denny,
	Unknown W Brackets, Benjamin Westfarer, Rob Eberhardt,
	Bill Edney, Kevin Newman, James Crompton, Matthew Mastracci,
	Doug Wright, Richard York, Kenneth Kolano, MegaZone,
	Thomas Verelst
*/

// =======================================================================
// TO DO
// =======================================================================

// PNG stretch?
// PNG - unclickable content
// load without ActiveX
// allow "IE7_OFF" in any given style sheet

// =======================================================================
// TEST/BUGGY
// =======================================================================

// hr{margin:1em auto} (doesn't look right in IE5)

// =======================================================================
// DONE
// =======================================================================

// box-sizing:border-box
// namespaced attribute selectors
// base64 encoded images
// support style switching
// simplified the XMLHttpRequest wrapper in ie7-xml-extras.js
// event handlers now refreshed on document.recalc
// document.recalc(true) reloads style sheets
// bug fix: min/max-width in quirks mode
// bug fix: empty selectors
// bug fix: quoted URLs in generated content
// bug fix: memory leak for PNG solution
// bug fix: "none" is now default for min/max-width/height
// bug fix: min/max-width/height preserved by document.recalc

if (!window.IE7) new function() {
try {
// -----------------------------------------------------------------------
// globals
// -----------------------------------------------------------------------
window.IE7 = this;
// in case of error...
var DUMMY = this.addModule = new Function;
// IE7 version info
this.toString = function(){return "IE7 version 0.9 (alpha)"};
// error reporting
var ie7_debug = /ie7_debug/.test(top.location.search);
var alert = (ie7_debug) ? function($message){window.alert(IE7+"\n\n"+$message)} : DUMMY;
// IE version info
var appVersion = navigator.appVersion.match(/MSIE (\d\.\d)/)[1];
var quirksMode = document.compatMode != "CSS1Compat";
// IE7 can be turned "off"
if (/ie7_off/.test(top.location.search) || appVersion < 5 ||
	!/^ms_/.test(document.documentElement.uniqueID)) return;
// if using the favelet then the document has already loaded
var complete = document.readyState == "complete";
// another global
var ie7HTML, ie7Layout; // loaded separately
// handy
var documentElement = document.documentElement, body, viewport, styleSheets = document.styleSheets;
var ANON = "!";
// -----------------------------------------------------------------------
// external
// -----------------------------------------------------------------------

// cache for the various modules that make up IE7.
//  modules are stored as functions. these are executed
//  after the style sheet text has been loaded.
// storing the modules as functions means that we avoid
//  name clashes with other modules.
var modules = {};
var loaded = false;
IE7.addModule = function($name, $script) {
	if (!modules[$name]) {
		if (loaded) eval("$script=" + String($script));
		modules[$name] = new $script();
	}
};

var $RELATIVE = /^[\w\.]+[^:]*$/;
function makePath($href, $path) {
	if ($RELATIVE.test($href)) $href = ($path || "") + $href;
	return $href;
};

function getPath($href, $path) {
	$href = makePath($href, $path);
	return $href.slice(0, $href.lastIndexOf("/") + 1);
};

// get the path to this script
var $script = document.scripts[document.scripts.length - 1];
// create global variables from the inner text of the IE7 script
try {
	eval($script.innerHTML);
} catch ($ignore) {
	// ignore errors
}
var path = getPath($script.src);
// we'll use microsoft's http request object to load external files
var httpRequest;
try {
	var $lib = (ScriptEngineMajorVersion() >= 5) ? "Msxml2" : "Microsoft";
	httpRequest = new ActiveXObject($lib + ".XMLHTTP");
} catch ($ignore) {
	// ActiveX disabled
}
var _fileCache = {};
function loadFile($href, $path) {
try {
	$href = makePath($href, $path);
	if (!_fileCache[$href]) {
		// easy to load a file huh?
		httpRequest.open("GET", $href, false);
		httpRequest.send();
		if (httpRequest.status == 0 || httpRequest.status == 200) {
			_fileCache[$href] = httpRequest.responseText;
		}
	}
} catch ($ignore) {
	alert("Error [1]: error loading file " + $href);
} finally {
	return _fileCache[$href] || "";
}};

// a small transparent image used as a placeholder
var BLANK_GIF = makePath("blank.gif", path);

// -----------------------------------------------------------------------
// OO support
// -----------------------------------------------------------------------

/*    ---   (require) /common/src?common.js       ---    */
/*
	common, version 1.0.4 (2005/06/05)
	Copyright 2005, Dean Edwards
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/

// this function may be used to cast any javascript object
//  to a common object
function ICommon(that) {
	if (that != null) {
		that.inherit = Common.prototype.inherit;
		that.specialize = Common.prototype.specialize;
	}
	return that;
};

// sub-classing
ICommon.specialize = function($prototype, $constructor) {
	// initialise class properties
	if (!$prototype) $prototype = {};
	if (!$constructor) $constructor = $prototype.constructor;
	if ($constructor == {}.constructor) $constructor = new Function("this.inherit()");
	// build the inheritance chain
	//  insert a dummy constructor between the ancestor
	//  and the new constructor. this allows standard
	//  prototype inheritance plus chained constructor
	//  functions.
	$constructor.valueOf = new Function("return this");
	$constructor.valueOf.prototype = new this.valueOf;
	$constructor.valueOf.prototype.specialize($prototype);
	$constructor.prototype = new $constructor.valueOf;
	$constructor.valueOf.prototype.constructor =
	$constructor.prototype.constructor = $constructor;
	$constructor.ancestor = this;
	$constructor.specialize = arguments.callee;
	$constructor.ancestorOf = this.ancestorOf;
	return $constructor;
};

// root of the inheritance chain
ICommon.valueOf = new Function("return this");

// common interface
ICommon.valueOf.prototype = {
constructor: ICommon,
inherit: function() {
//-
//   Call this method from any other method to call that method's ancestor.
//   If there is no ancestor function then this function will throw an error.
//-
	return arguments.callee.caller.ancestor.apply(this, arguments);
},
specialize: function(that) {
//-
//   Add the interface of another object to this object
//-
	// if this object is the prototype then specialize the /real/ prototype
	if (this == this.constructor.prototype && this.constructor.specialize) {
		return this.constructor.valueOf.prototype.specialize(that);
	}
	// add each of one of the source object's properties to this object
	for (var i in that) {
		switch (i) {
			case "constructor": // don't do this one!
			case "toString":    // do this one maually
			case "valueOf":     // ignore this one...
				continue;
		}
		// implement inheritance
		if (typeof that[i] == "function" && that[i] != this[i]) {
			that[i].ancestor = this[i];
		}
		// add the property
		this[i] = that[i];
	}
	// do the "toString" function manually
	if (that.toString != this.toString && that.toString != {}.toString) {
		that.toString.ancestor = this.toString;
		this.toString = that.toString;
	}
	return this;
}};

// create the root
function Common() {
//--
//   empty constructor function
//--
};
this.Common = ICommon.specialize({
constructor: Common,
toString: function() {
    return "[common " + (this.constructor.className || "Object") + "]";
},
instanceOf: function(klass) {
    return this.constructor == klass || klass.ancestorOf(this.constructor);
}
});
Common.className = "Common";
Common.ancestor = null;
Common.ancestorOf = function(klass) {
	// Is this class an ancestor of the supplied class?
	while (klass && klass.ancestor != this) klass = klass.ancestor;
	return Boolean(klass);
};

// preserve the common prototype so that we can tell when a
//  property of the root class has changed
Common.valueOf.ancestor = ICommon;

// c'est fini!
delete this.Common;

var Fix = Common.specialize({
	constructor: function() {
		this.fixes = [];
		this.recalcs = [];
	},
	init: DUMMY
});

// -----------------------------------------------------------------------
// IE5.0 compatibility
// -----------------------------------------------------------------------

/* FAVELET */

// load an external module to patch IE5.0 and override the functions above
if (appVersion < 5.5) eval(loadFile("ie7-ie5.js", path));

// -----------------------------------------------------------------------
// initialisation
// -----------------------------------------------------------------------

var _initialised = false;
IE7.init = function() {
try {
	// prevent further loading
	if (_initialised) return;
	_initialised = complete = true;

	// frequently used references
	body = document.body;
	viewport = (quirksMode) ? body : documentElement;

	// apply CSS/DOM fixes
	if (isHTML && ie7HTML) ie7HTML.apply();
	ie7CSS.apply();
	recalc();
	alert("loaded successfully");
} catch ($error) {
	alert("Error [2]: " + $error.description);
}};

// a store for functions that will be called when refreshing IE7
var recalcs = [];
function addRecalc($recalc) {
	recalcs.push($recalc);
};
function recalc() {
	cssQuery.clearCache();
	if (isHTML && ie7HTML) ie7HTML.recalc();
	// re-apply style sheet rules (re-calculate ie7 classes)
	ie7CSS.recalc();
	// apply global fixes to the document
	for (var i = 0; i < recalcs.length; i++) recalcs[i]();
};

// -----------------------------------------------------------------------
//  Parser
// -----------------------------------------------------------------------

/*    ---   (include) /my/src?ParseMaster.js   ---    */
/*
	ParseMaster, version 1.0.2 (2005-08-19)
	Copyright 2005, Dean Edwards
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/

/* a multi-pattern parser */

// KNOWN BUG: erroneous behavior when using escapeChar with a replacement value that is a function

function ParseMaster() {
	// constants
	var $EXPRESSION = 0, $REPLACEMENT = 1, $LENGTH = 2;
	// used to determine nesting levels
	var $GROUPS = /\(/g, $SUB_REPLACE = /\$\d/, $INDEXED = /^\$\d+$/,
	    $TRIM = /(['"])\1\+(.*)\+\1\1$/, $$ESCAPE = /\\./g, $QUOTE = /'/,
	    $$DELETED = /\x01[^\x01]*\x01/g;
	var self = this;
	// public
	this.add = function($expression, $replacement) {
		if (!$replacement) $replacement = "";
		// count the number of sub-expressions
		//  - add one because each pattern is itself a sub-expression
		var $length = (_internalEscape(String($expression)).match($GROUPS) || "").length + 1;
		// does the pattern deal with sub-expressions?
		if ($SUB_REPLACE.test($replacement)) {
			// a simple lookup? (e.g. "$2")
			if ($INDEXED.test($replacement)) {
				// store the index (used for fast retrieval of matched strings)
				$replacement = parseInt($replacement.slice(1)) - 1;
			} else { // a complicated lookup (e.g. "Hello $2 $1")
				// build a function to do the lookup
				var i = $length;
				var $quote = $QUOTE.test(_internalEscape($replacement)) ? '"' : "'";
				while (i) $replacement = $replacement.split("$" + i--).join($quote + "+a[o+" + i + "]+" + $quote);
				$replacement = new Function("a,o", "return" + $quote + $replacement.replace($TRIM, "$1") + $quote);
			}
		}
		// pass the modified arguments
		_add($expression || "/^$/", $replacement, $length);
	};
	// execute the global replacement
	this.exec = function($string) {
		_escaped.length = 0;
		return _unescape(_escape($string, this.escapeChar).replace(
			new RegExp(_patterns, this.ignoreCase ? "gi" : "g"), _replacement), this.escapeChar).replace($$DELETED, "");
	};
	// clear the patterns collection so that this object may be re-used
	this.reset = function() {
		_patterns.length = 0;
	};

	// private
	var _escaped = [];  // escaped characters
	var _patterns = []; // patterns stored by index
	var _toString = function(){return "(" + String(this[$EXPRESSION]).slice(1, -1) + ")"};
	_patterns.toString = function(){return this.join("|")};
	// create and add a new pattern to the patterns collection
	function _add() {
		arguments.toString = _toString;
		// store the pattern - as an arguments object (i think this is quicker..?)
		_patterns[_patterns.length] = arguments;
	}
	// this is the global replace function (it's quite complicated)
	function _replacement() {
		if (!arguments[0]) return "";
		var i = 1, j = 0, $pattern;
		// loop through the patterns
		while ($pattern = _patterns[j++]) {
			// do we have a result?
			if (arguments[i]) {
				var $replacement = $pattern[$REPLACEMENT];
				switch (typeof $replacement) {
					case "function": return $replacement(arguments, i);
					case "number": return arguments[$replacement + i];
				}
				var $delete = (arguments[i].indexOf(self.escapeChar) == -1) ? "" :
					"\x01" + arguments[i] + "\x01";
				return $delete + $replacement;
			// skip over references to sub-expressions
			} else i += $pattern[$LENGTH];
		}
	};
	// encode escaped characters
	function _escape($string, $escapeChar) {
		return $escapeChar ? $string.replace(new RegExp("\\" + $escapeChar + "(.)", "g"), function($match, $char) {
			_escaped[_escaped.length] = $char;
			return $escapeChar;
		}) : $string;
	};
	// decode escaped characters
	function _unescape($string, $escapeChar) {
		var i = 0;
		return $escapeChar ? $string.replace(new RegExp("\\" + $escapeChar, "g"), function() {
			return $escapeChar + (_escaped[i++] || "");
		}) : $string;
	};
	function _internalEscape($string) {
		return $string.replace($$ESCAPE, "");
	};
};
ParseMaster.prototype = {
	constructor: ParseMaster,
	ignoreCase: false,
	escapeChar: ""
};
Common.specialize(ParseMaster.prototype);
var Parser = ParseMaster.specialize({ignoreCase: true});

// -----------------------------------------------------------------------
//  cssQuery
// -----------------------------------------------------------------------

/*    ---   (include) /my/cssQuery/src?cssQuery.js   ---    */
/*
	cssQuery, version 2.0.2 (2005-08-19)
	Copyright: 2004-2005, Dean Edwards (http://dean.edwards.name/)
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/

// the following functions allow querying of the DOM using CSS selectors
var cssQuery = function() {
var version = "2.0.2";

// -----------------------------------------------------------------------
// main query function
// -----------------------------------------------------------------------

var $COMMA = /\s*,\s*/;
var cssQuery = function($selector, $$from) {
try {
	var $match = [];
	var $useCache = arguments.callee.caching && !$$from;
	var $base = ($$from) ? ($$from.constructor == Array) ? $$from : [$$from] : [document];
	// process comma separated selectors
	var $$selectors = parseSelector($selector).split($COMMA), i;
	for (i = 0; i < $$selectors.length; i++) {
		// convert the selector to a stream
		$selector = _toStream($$selectors[i]);
		// faster chop if it starts with id (MSIE only)
		if (isMSIE && $selector.slice(0, 3).join("") == " *#") {
			$selector = $selector.slice(2);
			$$from = _msie_selectById([], $base, $selector[1]);
		} else $$from = $base;
		// process the stream
		var j = 0, $token, $filter, $arguments, $cacheSelector = "";
		while (j < $selector.length) {
			$token = $selector[j++];
			$filter = $selector[j++];
			$cacheSelector += $token + $filter;
			// some pseudo-classes allow arguments to be passed
			//  e.g. nth-child(even)
			$arguments = "";
			if ($selector[j] == "(") {
				while ($selector[j++] != ")" && j < $selector.length) {
					$arguments += $selector[j];
				}
				$arguments = $arguments.slice(0, -1);
				$cacheSelector += "(" + $arguments + ")";
			}
			// process a token/filter pair use cached results if possible
			$$from = ($useCache && cache[$cacheSelector]) ?
				cache[$cacheSelector] : select($$from, $token, $filter, $arguments);
			if ($useCache) cache[$cacheSelector] = $$from;
		}
		$match = $match.concat($$from);
	}
	delete cssQuery.error;
	return $match;
} catch ($error) {
	cssQuery.error = $error;
	return [];
}};

// -----------------------------------------------------------------------
// public interface
// -----------------------------------------------------------------------

cssQuery.toString = function() {
	return "function cssQuery() {\n  [version " + version + "]\n}";
};

// caching
var cache = {};
cssQuery.caching = false;
cssQuery.clearCache = function($selector) {
	if ($selector) {
		$selector = _toStream($selector).join("");
		delete cache[$selector];
	} else cache = {};
};

// allow extensions
var modules = {};
var loaded = false;
cssQuery.addModule = function($name, $script) {
	if (loaded) eval("$script=" + String($script));
	modules[$name] = new $script();;
};

// hackery
cssQuery.valueOf = function($code) {
	return $code ? eval($code) : this;
};

// -----------------------------------------------------------------------
// declarations
// -----------------------------------------------------------------------

var selectors = {};
var pseudoClasses = {};
// a safari bug means that these have to be declared here
var AttributeSelector = {match: /\[([\w-]+(\|[\w-]+)?)\s*(\W?=)?\s*([^\]]*)\]/};
var attributeSelectors = [];

// -----------------------------------------------------------------------
// selectors
// -----------------------------------------------------------------------

// descendant selector
selectors[" "] = function($results, $from, $tagName, $namespace) {
	// loop through current selection
	var $element, i, j;
	for (i = 0; i < $from.length; i++) {
		// get descendants
		var $subset = getElementsByTagName($from[i], $tagName, $namespace);
		// loop through descendants and add to results selection
		for (j = 0; ($element = $subset[j]); j++) {
			if (thisElement($element) && compareNamespace($element, $namespace))
				$results.push($element);
		}
	}
};

// ID selector
selectors["#"] = function($results, $from, $id) {
	// loop through current selection and check ID
	var $element, j;
	for (j = 0; ($element = $from[j]); j++) if ($element.id == $id) $results.push($element);
};

// class selector
selectors["."] = function($results, $from, $className) {
	// create a RegExp version of the class
	$className = new RegExp("(^|\\s)" + $className + "(\\s|$)");
	// loop through current selection and check class
	var $element, i;
	for (i = 0; ($element = $from[i]); i++)
		if ($className.test($element.className)) $results.push($element);
};

// pseudo-class selector
selectors[":"] = function($results, $from, $pseudoClass, $arguments) {
	// retrieve the cssQuery pseudo-class function
	var $test = pseudoClasses[$pseudoClass], $element, i;
	// loop through current selection and apply pseudo-class filter
	if ($test) for (i = 0; ($element = $from[i]); i++)
		// if the cssQuery pseudo-class function returns "true" add the element
		if ($test($element, $arguments)) $results.push($element);
};

// -----------------------------------------------------------------------
// pseudo-classes
// -----------------------------------------------------------------------

pseudoClasses["link"] = function($element) {
	var $document = getDocument($element);
	if ($document.links) for (var i = 0; i < $document.links.length; i++) {
		if ($document.links[i] == $element) return true;
	}
};

pseudoClasses["visited"] = function($element) {
	// can't do this without jiggery-pokery
};

// -----------------------------------------------------------------------
// DOM traversal
// -----------------------------------------------------------------------

// IE5/6 includes comments (LOL) in it's elements collections.
// so we have to check for this. the test is tagName != "!". LOL (again).
var thisElement = function($element) {
	return ($element && $element.nodeType == 1 && $element.tagName != "!") ? $element : null;
};

// return the previous element to the supplied element
//  previousSibling is not good enough as it might return a text or comment node
var previousElementSibling = function($element) {
	while ($element && ($element = $element.previousSibling) && !thisElement($element)) continue;
	return $element;
};

// return the next element to the supplied element
var nextElementSibling = function($element) {
	while ($element && ($element = $element.nextSibling) && !thisElement($element)) continue;
	return $element;
};

// return the first child ELEMENT of an element
//  NOT the first child node (though they may be the same thing)
var firstElementChild = function($element) {
	return thisElement($element.firstChild) || nextElementSibling($element.firstChild);
};

var lastElementChild = function($element) {
	return thisElement($element.lastChild) || previousElementSibling($element.lastChild);
};

// return child elements of an element (not child nodes)
var childElements = function($element) {
	var $childElements = [];
	$element = firstElementChild($element);
	while ($element) {
		$childElements.push($element);
		$element = nextElementSibling($element);
	}
	return $childElements;
};

// -----------------------------------------------------------------------
// browser compatibility
// -----------------------------------------------------------------------

// all of the functions in this section can be overwritten. the default
//  configuration is for IE. The functions below reflect this. standard
//  methods are included in a separate module. It would probably be better
//  the other way round of course but this makes it easier to keep IE7 trim.

var isMSIE = true;

var isXML = function($element) {
	var $document = getDocument($element);
	return (typeof $document.mimeType == "unknown") ?
		/\.xml$/i.test($document.URL) :
		Boolean($document.mimeType == "XML Document");
};

// return the element's containing document
var getDocument = function($element) {
	return $element.ownerDocument || $element.document;
};

var getElementsByTagName = function($element, $tagName) {
	return ($tagName == "*" && $element.all) ? $element.all : $element.getElementsByTagName($tagName);
};

var compareTagName = function($element, $tagName, $namespace) {
	if ($tagName == "*") return thisElement($element);
	if (!compareNamespace($element, $namespace)) return false;
	if (!isXML($element)) $tagName = $tagName.toUpperCase();
	return $element.tagName == $tagName;
};

var compareNamespace = function($element, $namespace) {
	return !$namespace || ($namespace == "*") || ($element.scopeName == $namespace);
};

var getTextContent = function($element) {
	return $element.innerText;
};

function _msie_selectById($results, $from, id) {
	var $match, i, j;
	for (i = 0; i < $from.length; i++) {
		if ($match = $from[i].all.item(id)) {
			if ($match.id == id) $results.push($match);
			else if ($match.length != null) {
				for (j = 0; j < $match.length; j++) {
					if ($match[j].id == id) $results.push($match[j]);
				}
			}
		}
	}
	return $results;
};

// for IE5.0
if (![].push) Array.prototype.push = function() {
	for (var i = 0; i < arguments.length; i++) {
		this[this.length] = arguments[i];
	}
	return this.length;
};

// -----------------------------------------------------------------------
// query support
// -----------------------------------------------------------------------

// select a set of matching elements.
// "from" is an array of elements.
// "token" is a character representing the type of filter
//  e.g. ">" means child selector
// "filter" represents the tag name, id or class name that is being selected
// the function returns an array of matching elements
var $NAMESPACE = /\|/;
function select($$from, $token, $filter, $arguments) {
	if ($NAMESPACE.test($filter)) {
		$filter = $filter.split($NAMESPACE);
		$arguments = $filter[0];
		$filter = $filter[1];
	}
	var $results = [];
	if (selectors[$token]) {
		selectors[$token]($results, $$from, $filter, $arguments);
	}
	return $results;
};

// -----------------------------------------------------------------------
// parsing
// -----------------------------------------------------------------------

// convert css selectors to a stream of tokens and filters
//  it's not a real stream. it's just an array of strings.
var $STANDARD_SELECT = /^[^\s>+~]/;
var $$STREAM = /[\s#.:>+~()@]|[^\s#.:>+~()@]+/g;
function _toStream($selector) {
	if ($STANDARD_SELECT.test($selector)) $selector = " " + $selector;
	return $selector.match($$STREAM) || [];
};

var $WHITESPACE = /\s*([\s>+~(),]|^|$)\s*/g;
var $IMPLIED_ALL = /([\s>+~,]|[^(]\+|^)([#.:@])/g;
var parseSelector = function($selector) {
	return $selector
	// trim whitespace
	.replace($WHITESPACE, "$1")
	// e.g. ".class1" --> "*.class1"
	.replace($IMPLIED_ALL, "$1*$2");
};

var Quote = {
	toString: function() {return "'"},
	match: /^('[^']*')|("[^"]*")$/,
	test: function($string) {
		return this.match.test($string);
	},
	add: function($string) {
		return this.test($string) ? $string : this + $string + this;
	},
	remove: function($string) {
		return this.test($string) ? $string.slice(1, -1) : $string;
	}
};

var getText = function($text) {
	return Quote.remove($text);
};

var $ESCAPE = /([\/()[\]?{}|*+-])/g;
function regEscape($string) {
	return $string.replace($ESCAPE, "\\$1");
};

// -----------------------------------------------------------------------
// modules
// -----------------------------------------------------------------------

// -------- >>      insert modules here for packaging       << -------- \\

loaded = true;

// -----------------------------------------------------------------------
// return the query function
// -----------------------------------------------------------------------

return cssQuery;

}(); // cssQuery
cssQuery.caching = true;
cssQuery.addModule("ie7", function() {
	thisElement = function($element) {
		return ($element && $element.nodeType == 1 && $element.tagName != "!" && !$element.ie7_anon) ? $element : null;
	};
});
cssQuery.valueOf("getText=arguments[1]", getString);

// -----------------------------------------------------------------------
//  IE7 CSS
// -----------------------------------------------------------------------

// assume html unless explicitly defined
var isHTML = !cssQuery.valueOf("isXML(arguments[1])", documentElement);
var HEADER = ":link{ie7-link:link}:visited{ie7-link:visited}" + (isHTML ? "" : "*{margin:0}");

var ie7CSS = new (Fix.specialize({ // single instance
	parser: new Parser,
	screen: "",
	print: "",
	styles: [],
	init: function() {
		this.createStyleSheet();
		this.refresh();
	},
	refresh: function() {
		ie7CSS.styleSheet.cssText = HEADER + this.screen + this.print;
	},
	getInlineStyles: function() {
		// load inline styles
		var $$styleSheets = document.getElementsByTagName("style"), $styleSheet;
		for (var i = $$styleSheets.length - 1; ($styleSheet = $$styleSheets[i]); i--) {
			if (!$styleSheet.disabled && !$styleSheet.ie7) {
				this.styles.push($styleSheet.innerHTML);
			}
		}
	},
	apply: function() {
		this.getInlineStyles();
		this.refresh();
		new StyleSheet("screen");
		this.trash();
	},
	addFix: function($expression, $replacement) {
		this.parser.add($expression, $replacement);
	},
	recalc: function() {
		// we're going to read through all style rules.
		//  certain rules have had ie7 properties added to them.
		//   e.g. p{top:0; ie7_recalc2:1; left:0}
		//  this flags a property in the rule as needing a fix.
		//  the selector text is then used to query the document.
		//  we can then loop through the results of the query
		//  and fix the elements.
		// we ignore the IE7 rules - so count them in the header
		var $RECALCS = /ie7_recalc\d+/g;
		var $start = HEADER.match(/[{,]/g).length;
		// only calculate screen fixes. print fixes don't show up anyway
		var $$stop = $start + (this.screen.cssText.match(/\{/g)||"").length;
		var $$rules = this.styleSheet.rules, $rule;
		var $$calcs, $calc, $$elements, $element, i, j, k, id;
		// loop through all rules
		for (i = $start; i < $$stop; i++) {
			$rule = $$rules[i];
			// search for the "ie7_recalc" flag (there may be more than one)
			if ($rule && ($$calcs = $rule.style.cssText.match($RECALCS))) {
				// use the selector text to query the document
				$$elements = cssQuery($rule.selectorText);
				// if there are matching elements then loop
				//  through the recalc functions and apply them
				//  to each element
				if ($$elements.length) for (j = 0; j < $$calcs.length; j++) {
					// get the matching flag (e.g. ie7_recalc3)
					id = $$calcs[j];
					// extract the numeric id from the end of the flag
					//  and use it to index the collection of recalc
					//  functions
					$calc = ie7CSS.recalcs[id.slice(10)][2];
					for (k = 0; ($element = $$elements[k]); k++) {
						// apply the fix
						if ($element.currentStyle[id]) $calc($element);
					}
				}
			}
		}
	},
	// recalcs occur whenever the document is refreshed using document.recalc()
	addRecalc: function($propertyName, $test, $handler, $replacement) {
		$test = new RegExp("([{;\\s])" + $propertyName + "\\s*:\\s*" + $test + "[^;}]*");
		var $id = this.recalcs.length;
        if ($replacement) $replacement = $propertyName + ":" + $replacement;
		this.addFix($test, function($match, $offset) {
			return ($replacement ?  $match[$offset + 1] + $replacement : $match[$offset]) +
				";ie7-" + $match[$offset].slice(1) + ";ie7_recalc" + $id + ":1";
		});
		this.recalcs.push(arguments);
		return $id;
	},
	// retrieve the text of a style sheet
	getText: function($styleSheet) {
		// without the CSS2 module we assume CSS1, so it is safe to get Microsoft's stored text
		return $styleSheet.cssText || "";
	},
	createStyleSheet: function() {
		// create the IE7 style sheet
		if (complete || !isHTML) document.createStyleSheet();
		// this fixes a bug to do with the <base> tag
		else document.write("<style ie7=true></style>");
		// get the new style sheet
		this.styleSheet = styleSheets[styleSheets.length - 1];
		// flag it so we can ignore it during parsing
		this.styleSheet.ie7 = true;
		this.styleSheet.cssText = HEADER;
	},
	trash: function() {
		// trash the old style sheets
		for (var i = 0; i < styleSheets.length; i++) {
			if (!styleSheets[i].ie7 && styleSheets[i].cssText) {
				styleSheets[i].cssText = "";
			}
		}
	}
}));

// -----------------------------------------------------------------------
//  IE7 StyleSheet class
// -----------------------------------------------------------------------

function StyleSheet($media) {
	this.media = $media;
	this.load();
	ie7CSS[$media] = this;
	ie7CSS.refresh();
};
Common.specialize({
	constructor: StyleSheet,
	toString: function() {
		return "@media " + this.media + "{" + this.cssText + "}";
	},
	recalc: DUMMY,
	load: function() {
		this.cssText = "";
		this.getText();
		this.parse();
		this.cssText = decode(this.cssText);
		$fileCache = {};
	},
	getText: function() {
		// store for style sheet text
		var _inlineStyles = [].concat(ie7CSS.styles);
		// parse media decalarations
		var $MEDIA = /@media\s+([^{]*)\{([^@]+\})\s*\}/gi;
		var $ALL = /\ball\b|^$/i, $SCREEN = /\bscreen\b/i, $PRINT = /\bprint\b/i;
		function _parseMedia($cssText, $media) {
			_filterMedia.$value = $media;
			return $cssText.replace($MEDIA, _filterMedia);
		};
		function _filterMedia($$match, $media, $cssText) {
			$media = _simpleMedia($media);
			switch ($media) {
				case "screen":
				case "print":
					if ($media != _filterMedia.$value) return "";
				case "all":
					return $cssText;
			}
			return "";
		};
		function _simpleMedia($media) {
			if ($ALL.test($media)) return "all";
			else if ($SCREEN.test($media)) return ($PRINT.test($media)) ? "all" : "screen";
			else if ($PRINT.test($media)) return "print";
		};
		var self = this;
		function _getCSSText($styleSheet, $path, $media, $level) {
			var $cssText = "";
			if (!$level) {
				$media = _simpleMedia($styleSheet.media);
				$level = 0;
			}
			if ($media == "all" || $media == self.media) {
				// IE only allows importing style sheets three levels deep.
				// it will crash if you try to access a level below this
				if ($level < 3) {
					// loop through imported style sheets
					for (var i = 0; i < $styleSheet.imports.length; i++) {
						// call this function recursively to get all imported style sheets
						$cssText += _getCSSText($styleSheet.imports[i], getPath($styleSheet.href, $path), $media, $level + 1);
					}
				}
				// retrieve inline style or load an external style sheet
				$cssText += _encode($styleSheet.href ? _loadStyleSheet($styleSheet, $path) : _inlineStyles.pop() || "");
				$cssText = _parseMedia($cssText, self.media);
			}
			return $cssText;
		};
		// store loaded cssText URLs
		var $fileCache = {};
		// load an external style sheet
		function _loadStyleSheet($styleSheet, $path) {
			var $url = makePath($styleSheet.href, $path);
			// if the style sheet has already loaded then don't duplicate it
			if ($fileCache[$url]) return "";
			// load from source
			$fileCache[$url] = ($styleSheet.disabled) ? "" :
				_fixUrls(ie7CSS.getText($styleSheet, $path), getPath($styleSheet.href, $path));
			return $fileCache[$url];
		};
		// fix css paths
		// we're lumping all css text into one big style sheet so relative
		//  paths have to be fixed. this is necessary anyway because of other
		//  explorer bugs.
		var $URL = /(url\s*\(\s*['"]?)([\w\.]+[^:\)]*['"]?\))/gi;
		function _fixUrls($cssText, $pathname) {
			// hack & slash
			return $cssText.replace($URL, "$1" + $pathname.slice(0, $pathname.lastIndexOf("/") + 1) + "$2");
		};

		// load all style sheets in the document
		for (var i = 0; i < styleSheets.length; i++) {
			if (!styleSheets[i].disabled && !styleSheets[i].ie7) {
				this.cssText += _getCSSText(styleSheets[i]);
			}
		}
	}, // end: load
	parse: function() {
		this.cssText = ie7CSS.parser.exec(this.cssText);
	},
	recalc: DUMMY
});

// -----------------------------------------------------------------------
// encoding
// -----------------------------------------------------------------------

var Quote = cssQuery.valueOf("Quote");
var _strings = [];

function _encode($cssText) {
	return encoder.exec(safeString.exec($cssText));
};

function _encodeString($match, $offset) {
	return Quote + (_strings.push($match[$offset]) - 1) + Quote;
};

function getString($value) {
	return Quote.test($value) ? eval(_strings[eval($value)]) : $value;
};

var encoder = new Parser;
// comments
encoder.add(/\/\*[^*]*\*+([^\/][^*]*\*+)*\//);
// strings
encoder.add(/'[^']*'/, _encodeString);
encoder.add(/"[^"]*"/, _encodeString);
// white space
encoder.add(/\s+/, " ");
// get rid
encoder.add(/@(namespace|import)[^;\n]+[;\n]|<!\-\-|\-\->/);

var safeString = new Parser;
safeString.add(/\\'/, "\\x27");
safeString.add(/\\"/, "\\x22");

// -----------------------------------------------------------------------
// decoding
// -----------------------------------------------------------------------

var decoder = new Parser;
// comments
decoder.add(/'(\d+)'/, _decodeString);

function decode($cssText) {
	return decoder.exec($cssText);
};

function _decodeString($match, $offset) {
	return _strings[$match[$offset + 1]];
};

// -----------------------------------------------------------------------
// event handling
// -----------------------------------------------------------------------

var _handlers = [];

function addResize($handler) {
	addRecalc($handler);
	addEventHandler(window, "onresize", $handler);
};

// add an event handler (function) to an element
function addEventHandler($element, $type, $handler) {
	$element.attachEvent($type, $handler);
	// store the handler so it can be detached later
	_handlers.push(arguments);
};

// remove an event handler assigned to an element by IE7
function removeEventHandler($element, $type, $handler) {
try {
	$element.detachEvent($type, $handler);
} catch ($ignore) {
	// write a letter of complaint to microsoft..
}};

// remove event handlers (they eat memory)
addEventHandler(window, "onunload", function() {
	var $handler;
 	while ($handler = _handlers.pop()) {
 		removeEventHandler($handler[0], $handler[1], $handler[2]);
 	}
});

function register($handler, $element, $condition) { // -@DRE
	//var $set = $handler[$element.uniqueID];
	if (!$handler.elements) $handler.elements = {};
	if ($condition) $handler.elements[$element.uniqueID] = $element;
	else delete $handler.elements[$element.uniqueID];
	//return !$set && $condition;
	return $condition;
};

// -----------------------------------------------------------------------
// events
// -----------------------------------------------------------------------

addEventHandler(window, "onbeforeprint", function() {
	if (!ie7CSS.print) new StyleSheet("print");
	ie7CSS.print.recalc();
});

// -----------------------------------------------------------------------
// pixel conversion
// -----------------------------------------------------------------------

// this is handy because it means that web developers can mix and match
//  measurement units in their style sheets. it is not uncommon to
//  express something like padding in "em" units whilst border thickness
//  is most often expressed in pixels.

var PIXEL = /^\d+(px)?$/i;
var PERCENT = /^\d+%$/;
var getPixelValue = function($element, $value) {
	if (PIXEL.test($value)) return parseInt($value);
	var $style = $element.style.left;
	var $runtimeStyle = $element.runtimeStyle.left;
	$element.runtimeStyle.left = $element.currentStyle.left;
	$element.style.left = $value || 0;
	$value = $element.style.pixelLeft;
	$element.style.left = $style;
	$element.runtimeStyle.left = $runtimeStyle;
	return $value;
};

// create a temporary element which is used to inherit styles
//  from the target element. the temporary element can be resized
//  to determine pixel widths/heights
function createTempElement($tagName) {
	var $element = document.createElement($tagName || "object");
	$element.style.cssText = "position:absolute;padding:0;display:block;border:none;clip:rect(0 0 0 0);left:-9999";
	$element.ie7_anon = true;
	return $element;
};

// -----------------------------------------------------------------------
// generic
// -----------------------------------------------------------------------

var _IE7_ = "ie7-";

function isFixed($element) {
	return $element.currentStyle["ie7-position"] == "fixed";
};

// original style
function getDefinedStyle($element, $propertyName) {
	return $element.currentStyle[_IE7_ + $propertyName] || $element.currentStyle[$propertyName];
};

function setOverrideStyle($element, $propertyName, $value) {
	if ($element.currentStyle[_IE7_ + $propertyName] == null) {
		$element.runtimeStyle[_IE7_ + $propertyName] = $element.currentStyle[$propertyName];
	}
	$element.runtimeStyle[$propertyName] = $value;
};

function addTimer($object, $cssText, $url) {
	var $timer = setInterval(function() {
	try {
		// wait until the object has loaded
		if (!$object.load) return;
		$object.load($object, $cssText, $url);
		clearInterval($timer);
	} catch ($ignore) {
		// remote scripting
		clearInterval($timer);
	}}, 10);
};

// -----------------------------------------------------------------------
//  modules
// -----------------------------------------------------------------------

// -------- >>      insert modules here for packaging       << -------- \\

/*
	IE7, version 0.9 (alpha) (2005-08-19)
	Copyright: 2004-2005, Dean Edwards (http://dean.edwards.name/)
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/

IE7.addModule("ie7-html4", function() {

// don't bother with this for XML documents
if (!isHTML) return;

// -----------------------------------------------------------------------
// HTML Header
// -----------------------------------------------------------------------

// create default font-sizes
HEADER += "h1{font-size:2em}h2{font-size:1.5em;}h3{font-size:1.17em;}" +
	"h4{font-size:1em}h5{font-size:.83em}h6{font-size:.67em}";

// -----------------------------------------------------------------------
// IE7 HTML Factory
// -----------------------------------------------------------------------

var _fixed = {};

ie7HTML = new (Fix.specialize({ // single instance
	init: DUMMY,
	// fixes are a one-off, they are applied when the document is loaded
	addFix: function() {
		this.fixes.push(arguments);
	},
	apply: function() {
		for (var i = 0; i < this.fixes.length; i++) {
			var $match = cssQuery(this.fixes[i][0]);
			var $fix = this.fixes[i][1] || _fixElement;
			for (var j = 0; j < $match.length; j++) $fix($match[j]);
		}
	},
	// recalcs occur whenever the document is refreshed using document.recalc()
	addRecalc: function() {
		this.recalcs.push(arguments);
	},
	recalc: function() {
		// loop through the fixes
		for (var i = 0; i < this.recalcs.length; i++) {
			var $match = cssQuery(this.recalcs[i][0]);
			var $recalc = this.recalcs[i][1], $element;
			var $key = Math.pow(2, i);
			for (var j = 0; ($element = $match[j]); j++) {
				var $uniqueID = $element.uniqueID;
				if ((_fixed[$uniqueID] & $key) == 0) {
					$element = $recalc($element) || $element;
					_fixed[$uniqueID] |= $key;
				}
			}
		}
	}
})); // ie7HTML

// -----------------------------------------------------------------------
// <abbr>
// -----------------------------------------------------------------------

// provide support for the <abbr> tag.
//  this is a proper fix, it preserves the DOM structure and
//  <abbr> elements report the correct tagName & namespace prefix
ie7HTML.addFix("abbr");

// -----------------------------------------------------------------------
// <label>
// -----------------------------------------------------------------------

// bind to the first child control
ie7HTML.addRecalc("label", function($element) {
	if (!$element.htmlFor) {
		var $firstChildControl = cssQuery("input,textarea", $element)[0];
		if ($firstChildControl) {
			addEventHandler($element, "onclick", function() {
				$firstChildControl.click();
			});
		}
	}
});

// -----------------------------------------------------------------------
// <button>
// -----------------------------------------------------------------------

// IE bug means that innerText is submitted instead of "value"
ie7HTML.addRecalc("button,input", function($element) {
	if ($element.tagName == "BUTTON") {
		var $match = $element.outerHTML.match(/ value="([^"]*)"/i);
		$element.runtimeStyle.value = ($match) ? $match[1] : "";
	}
	// flag the button/input that was used to submit the form
	if ($element.type == "submit") {
		addEventHandler($element, "onclick", function() {
			$element.runtimeStyle.clicked = true;
			setTimeout("document.all." + $element.uniqueID + ".runtimeStyle.clicked=false", 1);
		});
	}
});

// -----------------------------------------------------------------------
// <form>
// -----------------------------------------------------------------------

// only submit "successful controls
var $UNSUCCESSFUL = /^(submit|reset|button)$/;
ie7HTML.addRecalc("form", function($element) {
	addEventHandler($element, "onsubmit", function() {
		for (var i = 0; i < $element.length; i++) {
			if (_unsuccessful($element[i])) {
				$element[i].disabled = true;
				setTimeout("document.all." + $element[i].uniqueID + ".disabled=false", 1);
			} else if ($element[i].tagName == "BUTTON" && $element[i].type == "submit") {
				setTimeout("document.all." + $element[i].uniqueID + ".value='" +
					$element[i].value + "'", 1);
				$element[i].value = $element[i].runtimeStyle.value;
			}
		}
	});
});
function _unsuccessful($element) {
	return $UNSUCCESSFUL.test($element.type) && !$element.disabled &&
		!$element.runtimeStyle.clicked;
};

// -----------------------------------------------------------------------
// <img>
// -----------------------------------------------------------------------

// get rid of the spurious tooltip produced by the alt attribute on images
ie7HTML.addRecalc("img", function($element) {
	if ($element.alt && !$element.title) $element.title = "";
});

// -----------------------------------------------------------------------
// Fix broken elements
// -----------------------------------------------------------------------

var $PREFIX = (appVersion < 5.5) ? "HTML:" : "";
function _fixElement($element) {
	var $fixedElement = document.createElement("<" + $PREFIX +
		$element.outerHTML.slice(1));
	if ($element.outerHTML.slice(-2) != "/>") {
		// remove child nodes and copy them to the new $element
		var $$endTag = "</"+ $element.tagName + ">", $nextSibling;
		while (($nextSibling = $element.nextSibling) && $nextSibling.outerHTML != $$endTag) {
			$fixedElement.appendChild($nextSibling);
		}
		// remove the closing tag
		if ($nextSibling) $nextSibling.removeNode();
	}
	// replace the broken tag with the namespaced version
	$element.parentNode.replaceChild($fixedElement, $element);
};

}); // addModule
/*
	IE7, version 0.9 (alpha) (2005-08-19)
	Copyright: 2004-2005, Dean Edwards (http://dean.edwards.name/)
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/
IE7.addModule("ie7-layout", function() {
// big, ugly box-model hack + min/max stuff

// #tantek > #erik > #dean { voice-family: hacker; }

// this module is useful to other modules so it is global
//  (all modules are anyway through the modules collection)
ie7Layout = this;

// -----------------------------------------------------------------------
// "layout"
// -----------------------------------------------------------------------

HEADER += "*{boxSizing:content-box}";

// does an element have "layout" ?
this.hasLayout = (appVersion < 5.5) ? function($element) {
	// element.currentStyle.hasLayout doesn't work for IE5.0
	return $element.clientWidth;
} : function($element) {
	return $element.currentStyle.hasLayout;
};

// give an element "layout"
this.boxSizing = function($element) {
	if (!ie7Layout.hasLayout($element)) {
	//#	$element.runtimeStyle.fixedHeight =
		$element.style.height = "0cm";
		if ($element.currentStyle.verticalAlign == "auto")
			$element.runtimeStyle.verticalAlign = "top";
		// when an element acquires "layout", margins no longer collapse correctly
		_collapseMargins($element);
	}
};

// -----------------------------------------------------------------------
// Margin Collapse
// -----------------------------------------------------------------------

function _collapseMargins($element) {
	if ($element != viewport && $element.currentStyle.position != "absolute") {
		collapseMarginTop($element);
		collapseMarginBottom($element);
	}
};

var firstElementChild = cssQuery.valueOf("firstElementChild");
var lastElementChild = cssQuery.valueOf("lastElementChild");

function collapseMarginTop($element) {
	if (!$element.runtimeStyle.marginTop) {
		var $parentElement = $element.parentElement;
		if ($parentElement && ie7Layout.hasLayout($parentElement) && $element == firstElementChild($parentElement)) return;
		var $firstChild = firstElementChild($element);
		if ($firstChild && $firstChild.currentStyle.styleFloat == "none" && ie7Layout.hasLayout($firstChild)) {
			collapseMarginTop($firstChild);
			$marginTop = _getMargin($element, $element.currentStyle.marginTop);
			$childMarginTop = _getMargin($firstChild, $firstChild.currentStyle.marginTop);
			if ($marginTop < 0 || $childMarginTop < 0) {
				$element.runtimeStyle.marginTop = $marginTop + $childMarginTop;
			} else {
				$element.runtimeStyle.marginTop = Math.max($childMarginTop, $marginTop);
			}
			$firstChild.runtimeStyle.marginTop = "0px";
		}
	}
};
eval(String(collapseMarginTop).replace(/Top/g, "Bottom").replace(/first/g, "last"));

function _getMargin($element, $value) {
	return ($value == "auto") ? 0 : getPixelValue($element, $value);
};

// -----------------------------------------------------------------------
// box-model
// -----------------------------------------------------------------------

// constants
var $UNIT = /^[.\d][\w%]*$/, $AUTO = /^(auto|0cm)$/, $NUMERIC = "[.\\d]";

var applyWidth, applyHeight;
function borderBox($element){
	applyWidth($element);
	applyHeight($element);
};

function fixWidth($HEIGHT) {
	applyWidth = function($element) {
		if (!PERCENT.test($element.currentStyle.width)) fixWidth($element);
		_collapseMargins($element);
	};

	function fixWidth($element, $value) {
		if (!$element.runtimeStyle.fixedWidth) {
			if (!$value) $value = $element.currentStyle.width;
			$element.runtimeStyle.fixedWidth = ($UNIT.test($value)) ? Math.max(0, getFixedWidth($element, $value)) : $value;
			setOverrideStyle($element, "width", $element.runtimeStyle.fixedWidth);
		}
	};

	function layoutWidth($element) {
		if (!isFixed($element)) {
			var $layoutParent = $element.offsetParent;
			while ($layoutParent && !ie7Layout.hasLayout($layoutParent)) $layoutParent = $layoutParent.offsetParent;
		}
		return ($layoutParent || viewport).clientWidth;
	};

	function getPixelWidth($element, $value) {
		if (PERCENT.test($value)) return parseInt(parseFloat($value) / 100 * layoutWidth($element));
		return getPixelValue($element, $value);
	};

	var getFixedWidth = function($element, $value) {
		var $borderBox = $element.currentStyle["box-sizing"] == "border-box";
		var $adjustment = 0;
		if (quirksMode && !$borderBox)
			$adjustment += getBorderWidth($element) + getPaddingWidth($element);
		else if (!quirksMode && $borderBox)
			$adjustment -= getBorderWidth($element) + getPaddingWidth($element);
		return getPixelWidth($element, $value) + $adjustment;
	};

	// easy way to get border thickness for elements with "layout"
	function getBorderWidth($element) {
		return $element.offsetWidth - $element.clientWidth;
	};

	// have to do some pixel conversion to get padding thickness :-(
	function getPaddingWidth($element) {
		return getPixelWidth($element, $element.currentStyle.paddingLeft) +
			getPixelWidth($element, $element.currentStyle.paddingRight);
	};
	// clone the getPaddingWidth function to make a getMarginWidth function
	eval(String(getPaddingWidth).replace(/padding/g, "margin").replace(/Padding/g, "Margin"));

// -----------------------------------------------------------------------
// min/max
// -----------------------------------------------------------------------

	HEADER += "*{minWidth:none;maxWidth:none;min-width:none;max-width:none}";

	// handle min-width property
	function minWidth($element) {
		// IE6 supports min-height so we frig it here
		//#if ($element.currentStyle.minHeight == "auto") $element.runtimeStyle.minHeight = 0;
		if ($element.currentStyle["min-width"] != null) {
			$element.style.minWidth = $element.currentStyle["min-width"];
		}
		if (register(minWidth, $element, $element.currentStyle.minWidth != "none")) {
			ie7Layout.boxSizing($element);
			fixWidth($element);
			resizeWidth($element);
		}
	};
	// clone the minWidth function to make a maxWidth function
	eval(String(minWidth).replace(/min/g, "max"));
	// expose these methods
	ie7Layout.minWidth = minWidth;
	ie7Layout.maxWidth = maxWidth;

	// apply min/max restrictions
	function resizeWidth($element) {
		// check boundaries
		var $rect = $element.getBoundingClientRect();
		var $width = $rect.right - $rect.left;

		if ($element.currentStyle.minWidth != "none" && $width <= getFixedWidth($element, $element.currentStyle.minWidth)) {
			$element.runtimeStyle.width = getFixedWidth($element, $element.currentStyle.minWidth);
		} else if ($element.currentStyle.maxWidth != "none" && $width >= getFixedWidth($element, $element.currentStyle.maxWidth)) {
			$element.runtimeStyle.width = getFixedWidth($element, $element.currentStyle.maxWidth);
		} else {
			$element.runtimeStyle.width = $element.runtimeStyle.fixedWidth; // || "auto";
		}
	};

// -----------------------------------------------------------------------
// right/bottom
// -----------------------------------------------------------------------

	function fixRight($element) {
		if (register(fixRight, $element, /^(fixed|absolute)$/.test($element.currentStyle.position) &&
		    getDefinedStyle($element, "left") != "auto" &&
		    getDefinedStyle($element, "right") != "auto" &&
		    $AUTO.test(getDefinedStyle($element, "width")))) {
		    	resizeRight($element);
		    	ie7Layout.boxSizing($element);
		}
	};
	ie7Layout.fixRight = fixRight;

	function resizeRight($element) {
		var $left = getPixelWidth($element, $element.runtimeStyle._left || $element.currentStyle.left);
		var $width = layoutWidth($element) - getPixelWidth($element, $element.currentStyle.right) -	$left - getMarginWidth($element);
		if (parseInt($element.runtimeStyle.width) == $width) return;
		$element.runtimeStyle.width = "";
		if (isFixed($element) || $HEIGHT || $element.offsetWidth < $width) {
	    	if (!quirksMode) $width -= getBorderWidth($element) + getPaddingWidth($element);
			if ($width < 0) $width = 0;
			$element.runtimeStyle.fixedWidth = $width;
			setOverrideStyle($element, "width", $width);
		}
	};

// -----------------------------------------------------------------------
// window.onresize
// -----------------------------------------------------------------------

	// handle window resize
	var _clientWidth = 0;
	addResize(function() {
		var i, $wider = (_clientWidth < viewport.clientWidth);
		_clientWidth = viewport.clientWidth;
		// resize elements with "min-width" set
		for (i in minWidth.elements) {
			var $element = minWidth.elements[i];
			var $fixedWidth = (parseInt($element.runtimeStyle.width) == getFixedWidth($element, $element.currentStyle.minWidth));
			if ($wider && $fixedWidth) $element.runtimeStyle.width = "";
			if ($wider == $fixedWidth) resizeWidth($element);
		}
		// resize elements with "max-width" set
		for (i in maxWidth.elements) {
			var $element = maxWidth.elements[i];
			var $fixedWidth = (parseInt($element.runtimeStyle.width) == getFixedWidth($element, $element.currentStyle.maxWidth));
			if (!$wider && $fixedWidth) $element.runtimeStyle.width = "";
			if ($wider != $fixedWidth) resizeWidth($element);
		}
		// resize elements with "right" set
		for (i in fixRight.elements) resizeRight(fixRight.elements[i]);
	});

// -----------------------------------------------------------------------
// fix CSS
// -----------------------------------------------------------------------
	if (window.IE7_BOX_MODEL !== false) {
		ie7CSS.addRecalc("width", $NUMERIC, quirksMode ? applyWidth : _collapseMargins);
	}
	ie7CSS.addRecalc("min-width", $NUMERIC, minWidth);
	ie7CSS.addRecalc("max-width", $NUMERIC, maxWidth);
	ie7CSS.addRecalc("right", $NUMERIC, fixRight);
};
ie7CSS.addRecalc("border-spacing", $NUMERIC, function($element) {
	if ($element.currentStyle.borderCollapse != "collapse") {
		$element.cellSpacing = getPixelValue($element, $element.currentStyle["border-spacing"]);
	}
});
ie7CSS.addRecalc("box-sizing", "content-box", this.boxSizing);
ie7CSS.addRecalc("box-sizing", "border-box", borderBox);

// clone the fixWidth function to create a fixHeight function
var _rotate = new ParseMaster;
_rotate.add(/Width/, "Height");
_rotate.add(/width/, "height");
_rotate.add(/Left/, "Top");
_rotate.add(/left/, "top");
_rotate.add(/Right/, "Bottom");
_rotate.add(/right/, "bottom");
eval(_rotate.exec(String(fixWidth)));

// apply box-model + min/max fixes
fixWidth();
fixHeight(true);

});/*
	IE7, version 0.9 (alpha) (2005-08-19)
	Copyright: 2004-2005, Dean Edwards (http://dean.edwards.name/)
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/

IE7.addModule("ie7-graphics", function() {
if (appVersion < 5.5) return; // IE5.0 not supported

// constants
// this filter is used to replace a PNG image
var $ALPHA_IMAGE_LOADER = "DXImageTransform.Microsoft.AlphaImageLoader";
var $FILTER = "progid:" + $ALPHA_IMAGE_LOADER + "(src='%1',sizingMethod='scale')";

// ** IE7 VARIABLE
// e.g. only apply the hack to files ending in ".png"
// IE7_PNG_SUFFIX = ".png";

// regular expression version of the above
var _pngTest = new RegExp((window.IE7_PNG_SUFFIX || "-trans.png") + "$", "i");
var _filtered = [];

// apply a filter
function _addFilter($element) {
	var $filter = $element.filters[$ALPHA_IMAGE_LOADER];
	if ($filter) {
		$filter.src = $element.src;
		$filter.enabled = true;
	} else {
		$element.runtimeStyle.filter = $FILTER.replace(/%1/, $element.src);
		_filtered.push($element);
	}
	// remove the real image
	$element.src = BLANK_GIF;
};
function _removeFilter($element) {
	$element.src = $element.pngSrc;
	$element.filters[$ALPHA_IMAGE_LOADER].enabled = false;
};

// -----------------------------------------------------------------------
//  support opacity (CSS3)
// -----------------------------------------------------------------------

ie7CSS.addFix(/opacity\s*:\s*([\d.]+)/, function($match, $offset) {
	return "zoom:1;filter:progid:DXImageTransform.Microsoft.Alpha(opacity=" +
		((parseFloat($match[$offset + 1]) * 100) || 1) + ")";
});

// -----------------------------------------------------------------------
//  fix PNG transparency (CSS background images)
// -----------------------------------------------------------------------


// replace background(-image): url(..) ..  with background(-image): .. ;filter: ..;
var $BACKGROUND = /background(-image)?\s*:\s*([^\(};]*)url\(([^\)]+)\)([^;}]*)/;
ie7CSS.addFix($BACKGROUND, function($match, $offset) {
	var $url = getString($match[$offset + 3]);
	return _pngTest.test($url) ? "filter:" +
		$FILTER.replace(/scale/, "crop").replace(/%1/, $url) + ";zoom:1;background" +
		  ($match[$offset + 1]||"") + ":" + ($match[$offset + 2]||"") + "none" +
		  ($match[$offset + 4]||"") : $match[$offset];
});

if (ie7HTML) {
// -----------------------------------------------------------------------
//  fix PNG transparency (HTML images)
// -----------------------------------------------------------------------

	ie7HTML.addRecalc("img,input", function($element) {
		if ($element.tagName == "INPUT" && $element.type != "image") return;
		_fixImg($element);
		addEventHandler($element, "onpropertychange", function() {
			if (!_printing && event.propertyName == "src" &&
				$element.src.indexOf(BLANK_GIF) == -1) _fixImg($element);
		});
	});
	var $BASE64 = /^data:.*;base64/i;
	var _base64Path = makePath("ie7-base64.php", path);
	function _fixImg($element) {
		if (_pngTest.test($element.src)) {
			// we have to preserve width and height
			var $image = new Image($element.width, $element.height);
			$image.onload = function() {
				$element.width = $image.width;
				$element.height = $image.height;
				$image = null;
			};
			$image.src = $element.src;
			// store the original url (we'll put it back when it's printed)
			$element.pngSrc = $element.src;
			// add the AlphaImageLoader thingy
			_addFilter($element);
		} else if ($BASE64.test($element.src)) {
			$element.src = _base64Path + "?" + $element.src.slice(5);
		}
	};


// -----------------------------------------------------------------------
// <object>
// -----------------------------------------------------------------------

	// fix [type=image/*]
	var $IMAGE = /^image/i;
	var _objectPath = makePath("ie7-object.htc", path);
	ie7HTML.addRecalc("object", function($element) {
		if ($IMAGE.test($element.type)) {
		 	var $object = document.createElement("<object type=text/x-scriptlet>");
		 	$object.style.width = $element.currentStyle.width;
		 	$object.style.height = $element.currentStyle.height;
		//-	$object.title = $element.title;
		 	$object.data = _objectPath;
			var $url = makePath($element.data, getPath(location.href));
			$element.parentNode.replaceChild($object, $element);
			cssQuery.clearCache("object");
			addTimer($object, "", $url);
			return $object;
		}
	});
}

// assume that background images should not be printed
//  (if they are not transparent then they'll just obscure content)
// but we'll put foreground images back...
var _printing = false;
addEventHandler(window, "onbeforeprint", function() {
	_printing = true;
	for (var i = 0; i < _filtered.length; i++) _removeFilter(_filtered[i]);
});
addEventHandler(window, "onafterprint", function() {
	for (var i = 0; i < _filtered.length; i++) _addFilter(_filtered[i]);
	_printing = false;
});

});/*
	IE7, version 0.9 (alpha) (2005-08-19)
	Copyright: 2004-2005, Dean Edwards (http://dean.edwards.name/)
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/
IE7.addModule("ie7-fixed", function() {
	// some things to consider for this hack.
	// the document body requires a fixed background. even if
	//  it is just a blank image.
	// you have to use setExpression instead of onscroll, this
	//  together with a fixed body background helps avoid the
	//  annoying screen flicker of other solutions.

	ie7CSS.addRecalc("position", "fixed", _positionFixed, "absolute");
	ie7CSS.addRecalc("background(-attachment)?", "[^};]*fixed", _backgroundFixed);

	// scrolling is relative to the documentElement (HTML tag) when in
	//  standards mode, otherwise it's relative to the document body
	var _viewport = (quirksMode) ? "body" : "documentElement";

	var _fixBackground = function() {
		// this is required by both position:fixed and background-attachment:fixed.
		// it is necessary for the document to also have a fixed background image.
		// we can fake this with a blank image if necessary
		if (body.currentStyle.backgroundAttachment != "fixed") {
			if (body.currentStyle.backgroundImage == "none") {
				body.runtimeStyle.backgroundRepeat = "no-repeat";
				body.runtimeStyle.backgroundImage = "url(" + BLANK_GIF + ")"; // dummy
			}
			body.runtimeStyle.backgroundAttachment = "fixed";
		}
		_fixBackground = DUMMY;
	};

	var _tmp = createTempElement("img");

	// clone a "left" function to create a "top" function
	function _rotate($function) {
		return _rotater.exec(String($function));
	};
	var _rotater = new ParseMaster;
	_rotater.add(/Left/, "Top");
	_rotater.add(/left/, "top");
	_rotater.add(/Width/, "Height");
	_rotater.add(/width/, "height");
	_rotater.add(/right/, "bottom");
	_rotater.add(/X/, "Y");

	function _isFixed($element) {
		return ($element) ? isFixed($element) || _isFixed($element.parentElement) : false;
	};

	function setExpression($element, $propertyName, $$expression) {
		setTimeout("document.all." + $element.uniqueID + ".runtimeStyle.setExpression('" +
			$propertyName + "','" + $$expression + "')", 0);
	};

// -----------------------------------------------------------------------
//  backgroundAttachment: fixed
// -----------------------------------------------------------------------

	function _backgroundFixed($element) {
		if (register(_backgroundFixed, $element,
			$element.currentStyle.backgroundAttachment == "fixed" && !$element.contains(body))) {
				_fixBackground();
				backgroundLeft($element);
				backgroundTop($element);
				_backgroundPosition($element);
		}
	};

	function _backgroundPosition($element) {
		_tmp.src = $element.currentStyle.backgroundImage.slice(5, -2);
		var $parentElement = ($element.canHaveChildren) ? $element : $element.parentElement;
		$parentElement.appendChild(_tmp);
		setOffsetLeft($element);
		setOffsetTop($element);
		$parentElement.removeChild(_tmp);
	};

	function backgroundLeft($element) {
		$element.style.backgroundPositionX = $element.currentStyle.backgroundPositionX;
		if (!_isFixed($element)) {
			var $$expression = "(parseInt(runtimeStyle.offsetLeft)+document." +
				 _viewport + ".scrollLeft)||0";
			setExpression($element, "backgroundPositionX", $$expression);
		}
	};
	eval(_rotate(backgroundLeft));

	function setOffsetLeft($element) {
		var $propertyName = _isFixed($element) ? "backgroundPositionX" : "offsetLeft";
		$element.runtimeStyle[$propertyName] =
			getOffsetLeft($element, $element.style.backgroundPositionX) -
			$element.getBoundingClientRect().left - $element.clientLeft + 2;
	};
	eval(_rotate(setOffsetLeft));

	function getOffsetLeft($element, $position) {
		switch ($position) {
			case "left":
			case "top":
				return 0;
			case "right":
			case "bottom":
				return viewport.clientWidth - _tmp.offsetWidth;
			case "center":
				return (viewport.clientWidth - _tmp.offsetWidth) / 2;
			default:
				if (PERCENT.test($position)) {
					return parseInt((viewport.clientWidth - _tmp.offsetWidth) *
						parseFloat($position) / 100);
				}
				_tmp.style.left = $position;
				return _tmp.offsetLeft;
		}
	};
	eval(_rotate(getOffsetLeft));

// -----------------------------------------------------------------------
//  position: fixed
// -----------------------------------------------------------------------

	function _positionFixed($element) {
		if (register(_positionFixed, $element, isFixed($element))) {
			setOverrideStyle($element, "position",  "absolute");
			setOverrideStyle($element, "left",  $element.currentStyle.left);
			setOverrideStyle($element, "top",  $element.currentStyle.top);
			_fixBackground();
			if (ie7Layout) ie7Layout.fixRight($element);
			_foregroundPosition($element);
		}
	};

	function _foregroundPosition($element, $recalc) {
		positionTop($element, $recalc);
		positionLeft($element, $recalc, true);
		if (!$element.runtimeStyle.autoLeft && $element.currentStyle.marginLeft == "auto" &&
			$element.currentStyle.right != "auto") {
			var $left = viewport.clientWidth - getPixelWidth($element, $element.currentStyle.right) -
				getPixelWidth($element, $element.runtimeStyle._left) - $element.clientWidth;
			if ($element.currentStyle.marginRight == "auto") $left = parseInt($left / 2);
			if (_isFixed($element.offsetParent)) $element.runtimeStyle.pixelLeft += $left;
			else $element.runtimeStyle.shiftLeft = $left;
		}
		clipWidth($element);
		clipHeight($element);
	};

	function clipWidth($element) {
		if ($element.currentStyle.width != "auto") {
			var $rect = $element.getBoundingClientRect();
			var $width = $element.offsetWidth - viewport.clientWidth + $rect.left - 2;
			if ($width >= 0) {
				$width = Math.max(getPixelValue($element, $element.currentStyle.width) - $width, 0);
				setOverrideStyle($element, "width",	$width);
			}
		}
	};
	eval(_rotate(clipWidth));

	function positionLeft($element, $recalc) {
		// if the element's width is in % units then it must be recalculated
		//  with respect to the viewport
		if (!$recalc && PERCENT.test($element.currentStyle.width)) {
			$element.runtimeStyle.fixWidth = $element.currentStyle.width;
		}
		if ($element.runtimeStyle.fixWidth) {
			$element.runtimeStyle.width = getPixelWidth($element, $element.runtimeStyle.fixWidth);
		}
		if ($recalc) {
			// if the element is fixed on the right then no need to recalculate
			if (!$element.runtimeStyle.autoLeft) return;
		} else {
			$element.runtimeStyle.shiftLeft = 0;
			$element.runtimeStyle._left = $element.currentStyle.left;
			// is the element fixed on the right?
			$element.runtimeStyle.autoLeft = $element.currentStyle.right != "auto" &&
				$element.currentStyle.left == "auto";
		}
		// reset the element's "left" value and get it's natural position
		$element.runtimeStyle.left = "";
		$element.runtimeStyle.screenLeft = getScreenLeft($element);
		$element.runtimeStyle.pixelLeft = $element.runtimeStyle.screenLeft;
		// if the element is contained by another fixed element then there is no need to
		//  continually recalculate it's left position
		if (!$recalc && !_isFixed($element.offsetParent)) {
			// onsrcoll produces jerky movement, so we use an expression
			var $$expression = "runtimeStyle.screenLeft+runtimeStyle.shiftLeft+document." +
				_viewport + ".scrollLeft";
			setExpression($element, "pixelLeft", $$expression);
		}
	};
	// clone this function so we can do "top"
	eval(_rotate(positionLeft));

	// i've forgotten how this works...
	function getScreenLeft($element) { // thanks to kevin newman (captainn)
		var $screenLeft = $element.offsetLeft, $nested = 1;
		if ($element.runtimeStyle.autoLeft) {
			$screenLeft = viewport.clientWidth - $element.offsetWidth -
				getPixelWidth($element, $element.currentStyle.right);
		}
		// accommodate margins
		if ($element.currentStyle.marginLeft != "auto") {
			$screenLeft -= getPixelWidth($element, $element.currentStyle.marginLeft);
		}
		while ($element = $element.offsetParent) {
			if ($element.currentStyle.position != "static") $nested = -1;
			$screenLeft += $element.offsetLeft * $nested;
		}
		return $screenLeft;
	};
	eval(_rotate(getScreenLeft));

	function getPixelWidth($element, $value) {
		if (PERCENT.test($value)) return parseInt(parseFloat($value) / 100 * viewport.clientWidth);
		return getPixelValue($element, $value);
	};
	eval(_rotate(getPixelWidth));

// -----------------------------------------------------------------------
//  capture window resize
// -----------------------------------------------------------------------

	function _resize() {
		// if the window has been resized then some positions need to be
		//  recalculated (especially those aligned to "right" or "top"
		var $elements = _backgroundFixed.elements;
		for (var i in $elements) _backgroundPosition($elements[i]);
		$elements = _positionFixed.elements;
		for (i in $elements) {
			_foregroundPosition($elements[i], true);
			// do this twice to be sure - hackish, I know :-)
			_foregroundPosition($elements[i], true);
		}
		_timer = 0;
	};

	// use a timer for some reason.
	//  (sometimes this is a good way to prevent resize loops)
	var _timer;
	addResize(function() {
		if (!_timer) _timer = setTimeout(_resize, 0);
	});

});/*
	IE7, version 0.9 (alpha) (2005-08-19)
	Copyright: 2004-2005, Dean Edwards (http://dean.edwards.name/)
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/

IE7.addModule("ie7-css2-selectors", function() {

/*
	cssQuery, version 2.0.2 (2005-08-19)
	Copyright: 2004-2005, Dean Edwards (http://dean.edwards.name/)
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/

cssQuery.addModule("css-level2", function() {

// -----------------------------------------------------------------------
// selectors
// -----------------------------------------------------------------------

// child selector
selectors[">"] = function($results, $from, $tagName, $namespace) {
	var $element, i, j;
	for (i = 0; i < $from.length; i++) {
		var $subset = childElements($from[i]);
		for (j = 0; ($element = $subset[j]); j++)
			if (compareTagName($element, $tagName, $namespace))
				$results.push($element);
	}
};

// sibling selector
selectors["+"] = function($results, $from, $tagName, $namespace) {
	for (var i = 0; i < $from.length; i++) {
		var $element = nextElementSibling($from[i]);
		if ($element && compareTagName($element, $tagName, $namespace))
			$results.push($element);
	}
};

// attribute selector
selectors["@"] = function($results, $from, $attributeSelectorID) {
	var $test = attributeSelectors[$attributeSelectorID].test;
	var $element, i;
	for (i = 0; ($element = $from[i]); i++)
		if ($test($element)) $results.push($element);
};

// -----------------------------------------------------------------------
// pseudo-classes
// -----------------------------------------------------------------------

pseudoClasses["first-child"] = function($element) {
	return !previousElementSibling($element);
};

pseudoClasses["lang"] = function($element, $code) {
	$code = new RegExp("^" + $code, "i");
	while ($element && !$element.getAttribute("lang")) $element = $element.parentNode;
	return $element && $code.test($element.getAttribute("lang"));
};

// -----------------------------------------------------------------------
//  attribute selectors
// -----------------------------------------------------------------------

// constants
AttributeSelector.NS_IE = /\\:/g;
AttributeSelector.PREFIX = "@";
// properties
AttributeSelector.tests = {};
// methods
AttributeSelector.replace = function($match, $attribute, $namespace, $compare, $value) {
	var $key = this.PREFIX + $match;
	if (!attributeSelectors[$key]) {
		$attribute = this.create($attribute, $compare || "", $value || "");
		// store the selector
		attributeSelectors[$key] = $attribute;
		attributeSelectors.push($attribute);
	}
	return attributeSelectors[$key].id;
};
AttributeSelector.parse = function($selector) {
	$selector = $selector.replace(this.NS_IE, "|");
	var $match;
	while ($match = $selector.match(this.match)) {
		var $replace = this.replace($match[0], $match[1], $match[2], $match[3], $match[4]);
		$selector = $selector.replace(this.match, $replace);
	}
	return $selector;
};
AttributeSelector.create = function($propertyName, $test, $value) {
	var $attributeSelector = {};
	$attributeSelector.id = this.PREFIX + attributeSelectors.length;
	$attributeSelector.name = $propertyName;
	$test = this.tests[$test];
	$test = $test ? $test(this.getAttribute($propertyName), getText($value)) : false;
	$attributeSelector.test = new Function("e", "return " + $test);
	return $attributeSelector;
};
AttributeSelector.getAttribute = function($name) {
	switch ($name.toLowerCase()) {
		case "id":
			return "e.id";
		case "class":
			return "e.className";
		case "for":
			return "e.htmlFor";
		case "href":
			if (isMSIE) {
				// IE always returns the full path not the fragment in the href attribute
				//  so we RegExp it out of outerHTML. Opera does the same thing but there
				//  is no way to get the original attribute.
				return "String((e.outerHTML.match(/href=\\x22?([^\\s\\x22]*)\\x22?/)||[])[1]||'')";
			}
	}
	return "e.getAttribute('" + $name.replace($NAMESPACE, ":") + "')";
};

// -----------------------------------------------------------------------
//  attribute selector tests
// -----------------------------------------------------------------------

AttributeSelector.tests[""] = function($attribute) {
	return $attribute;
};

AttributeSelector.tests["="] = function($attribute, $value) {
	return $attribute + "==" + Quote.add($value);
};

AttributeSelector.tests["~="] = function($attribute, $value) {
	return "/(^| )" + regEscape($value) + "( |$)/.test(" + $attribute + ")";
};

AttributeSelector.tests["|="] = function($attribute, $value) {
	return "/^" + regEscape($value) + "(-|$)/.test(" + $attribute + ")";
};

// -----------------------------------------------------------------------
//  parsing
// -----------------------------------------------------------------------

// override parseSelector to parse out attribute selectors
var _parseSelector = parseSelector;
parseSelector = function($selector) {
	return _parseSelector(AttributeSelector.parse($selector));
};

}); // addModule
var AttributeSelector = cssQuery.valueOf("AttributeSelector");

// -----------------------------------------------------------------------
//  IE7 StyleSheet class
// -----------------------------------------------------------------------

// constants
var $HYPERLINK = /a(#[\w-]+)?(\.[\w-]+)?:(hover|active)/i;
var $BRACE1 = /\s*\{\s*/, $BRACE2 = /\s*\}\s*/, $COMMA = /\s*\,\s*/;
var $FIRST_LINE_LETTER = /(.*)(:first-(line|letter))/;

StyleSheet.prototype.specialize({
	parse: function() {
		this.inherit();
		// parse the style sheet
		var $offset = ie7CSS.rules.length;
		var $$rules = this.cssText.split($BRACE2), $rule;
		var $$selectors, $cssText, i, j;
		for (i = 0; i < $$rules.length; i++) {
			$rule = $$rules[i].split($BRACE1);
			$$selectors = $rule[0].split($COMMA);
			$cssText = $rule[1];
			for (j = 0; j < $$selectors.length; j++) {
				$$selectors[j] = $cssText ? this.createRule($$selectors[j], $cssText) : "";
			}
			$$rules[i] = $$selectors.join("\n");
		}
		this.cssText = $$rules.join("\n");
		this.rules = ie7CSS.rules.slice($offset);
	},
	recalc: function() {
		var $rule, i;
		for (i = 0; ($rule = this.rules[i]); i++) $rule.recalc();
	},
	createRule: function($selector, $cssText) {
		if (ie7CSS.UNKNOWN.test($selector)) {
			var $match;
			if ($match = $selector.match(PseudoElement.MATCH)) {
				return new PseudoElement($match[1], $match[2], $cssText);
			} else if ($match = $selector.match(DynamicRule.MATCH)) {
				if (!isHTML || !$HYPERLINK.test($match) || DynamicRule.COMPLEX.test($match)) {
					return new DynamicRule($selector, $match[1], $match[2], $match[3], $cssText);
				}
			} else return new Rule($selector, $cssText);
		}
		return $selector + " {" + $cssText + "}";
	}
});

// -----------------------------------------------------------------------
//  IE7 CSS
// -----------------------------------------------------------------------

ie7CSS.specialize({
	// collections
	rules: [],
	pseudoClasses: cssQuery.valueOf("pseudoClasses"),
	dynamicPseudoClasses: {},
	// cssQuery cache
	cache: cssQuery.valueOf("cache"),
	// classes
	Rule: Rule,
	DynamicRule: DynamicRule,
	PseudoElement: PseudoElement,
	DynamicPseudoClass: DynamicPseudoClass,
	// create regular expressions
	apply: function() {
		var $pseudoClasses = this.pseudoClasses + "|before|after|" + this.dynamicPseudoClasses;
		$pseudoClasses = $pseudoClasses.replace(/(link|visited)\|/g, "");
		this.UNKNOWN = new RegExp("[>+~\[]|([:.])[\\w-()]+\\1|:(" + $pseudoClasses + ")");
		var $complex = "[^\\s(]+\\s*[+~]|@\\d+|:(";
		Rule.COMPLEX = new RegExp($complex + $pseudoClasses + ")", "g");
		DynamicRule.COMPLEX = new RegExp($complex + this.pseudoClasses + ")", "g");
		DynamicRule.MATCH = new RegExp("(.*):(" + this.dynamicPseudoClasses + ")(.*)");
		PseudoElement.MATCH = /(.*):(before|after).*/;
		this.inherit();
	},
	recalc: function() {
		this.screen.recalc();
		this.inherit();
	},
	getText: function($styleSheet, $path) {
		// override getCSSText function defined in ie7-core.js.
		// explorer will trash unknown selectors (it converts them to "UNKNOWN").
		// so we must reload external style sheets (internal style sheets can have their text
		//  extracted through the innerHTML property).
			// load the style sheet text from an external file
		return httpRequest ? (loadFile($styleSheet.href, $path) || $styleSheet.cssText)
			:  this.inherit($styleSheet);
	},
	addEventHandler: function($element, $type, $handler) {
		addEventHandler($element, $type, $handler);
	}
}); // ie7CSS;

// -----------------------------------------------------------------------
// IE7 style rules
// -----------------------------------------------------------------------

// constructor
function Rule($selector, $cssText) {
	this.id = ie7CSS.rules.length;
	this.className = Rule.PREFIX + this.id;
	$selector = ($selector).match($FIRST_LINE_LETTER) || $selector || "*";
	this.selector = $selector[1] || $selector;
	this.selectorText = Rule.simple(this.selector) + "." + this.className + ($selector[2] || "");
	this.cssText = $cssText;
	this.MATCH = new RegExp("\\s" + this.className + "(\\s|$)", "g");
	ie7CSS.rules.push(this);
	this.init();
};
// protoytype
Common.specialize({
	// properties
	constructor: Rule,
	toString: function() {
		return this.selectorText + " {" + this.cssText + "}";
	},
//- id: 0,
//- className: "",
//- selector: "",
//- cssText: "",
//- MATCH: null,
	// methods
	init: DUMMY,
	add: function($element) {
		// allocate this class
		$element.className += " " + this.className;
	},
	remove: function($element) {
		// deallocate this class
		$element.className = $element.className.replace(this.MATCH, "$1");
	},
	recalc: function() {
		// execute the underlying css query for this class
		var $match = ie7CSS.cache[" *." + this.className] = cssQuery(this.selector);
		// add the class name for all matching elements
		for (i = 0; i < $match.length; i++) this.add($match[i]);
	}
});
// constants
Rule.PREFIX = "ie7_class";
Rule.CHILD = />/g;
// class methods
Rule.simple = function($selector) {
	// attempt to preserve specificity for "loose" parsing by
	//  removing unknown tokens from a css selector but keep as
	//  much as we can..
	$selector = AttributeSelector.parse($selector);
	return $selector.replace(this.COMPLEX, "").replace(this.CHILD, " ");
};

// -----------------------------------------------------------------------
// IE7 dynamic style
// -----------------------------------------------------------------------

// class properties:
// attach: the element that an event handler will be attached to
// target: the element that will have the IE7 class applied

// constructor
function DynamicRule($selector, $attach, $dynamicPseudoClass, $target, $cssText) {
	// initialise object properties
	this.attach = $attach || "*";
	this.dynamicPseudoClass = ie7CSS.dynamicPseudoClasses[$dynamicPseudoClass];
	this.target = $target;
	this.inherit($selector, $cssText);
};
// protoytype
Rule.specialize({
	// properties
	constructor: DynamicRule,
//- attach: "",
//- dynamicPseudoClass: null,
//- target: "",
	// methods
	recalc: function() {
		// execute the underlying css query for this class
		var $match = cssQuery(this.attach);
		// process results
		for (var i = 0; i < $match.length; i++) {
			// retrieve the event handler's target $element(s)
			var $target = (this.target) ? cssQuery(this.target, $match[i]) : [$match[i]];
			// attach event handlers for dynamic pseudo-classes
			if ($target.length) this.dynamicPseudoClass.apply($match[i], $target, this);
		}
	}
});

// -----------------------------------------------------------------------
// IE7 pseudo elements
// -----------------------------------------------------------------------

// constants
var $ATTR = /^attr/;
var $URL = /^url\s*\(\s*([^)]*)\)$/;
var $MAP = {
	before0: "beforeBegin",
	before1: "afterBegin",
	after0: "afterEnd",
	after1: "beforeEnd"
};

var _contentPath = makePath("ie7-content.htc", path) + "?";

// CSS text required by the "content" property
HEADER += ".ie7_anon{display:none}";

// constructor
function PseudoElement($selector, $position, $cssText) {
	// initialise object properties
	this.position = $position;
	var $$content = $cssText.match(PseudoElement.CONTENT), $match, $entity;
	if ($$content) {
		$$content = $$content[1];
		$match = $$content.split(/\s+/);
		for (var i = 0; ($entity = $match[i]); i++) {
			$match[i] = $ATTR.test($entity) ? {attr: $entity.slice(5, -1)} :
				($entity.charAt(0) == "'") ? getString($entity) : decode($entity);
		}
		$$content = $match;
	}
	this.content = $$content;
	// CSS text needs to be decoded immediately
	this.inherit($selector, decode($cssText));
};
// prototype
Rule.specialize({
	constructor: PseudoElement,
	toString: function() {
		return "." + this.className + "{display:inline}";
	},
	init: function() {
		// execute the underlying css query for this class
		this.match = cssQuery(this.selector);
		for (var i = 0; i < this.match.length; i++) {
			var $runtimeStyle = this.match[i].runtimeStyle;
			if (!$runtimeStyle[this.position]) $runtimeStyle[this.position] = {cssText:""};
			$runtimeStyle[this.position].cssText += ";" + this.cssText;
			if (this.content != null) $runtimeStyle[this.position].content = this.content;
		}
	},
	recalc: function() {
		if (this.content == null) return;
		for (var i = 0; i < this.match.length; i++) {
			this.create(this.match[i]);
		}
	},
	create: function($target) {
		var $generated = $target.runtimeStyle[this.position];
		if ($generated) {
		//#	// insert the pseudo element
		//#	this.create($target, $generated.content, $generated.cssText.replace(/'/g, '"'));
			// copy the array of values
			var $content = [].concat($generated.content || "");
			for (var j = 0; j < $content.length; j++) {
				if (typeof $content[j] == "object") {
					$content[j] = $target.getAttribute($content[j].attr);
				}
			}
			$content = $content.join("");
			var $url = $content.match($URL);
			var $html = PseudoElement[$url?"OBJECT":"ANON"].replace(/%1/, this.className);
			var $$cssText = $generated.cssText.replace(/'/g, '"');
			var $$position = $MAP[this.position + Number($target.canHaveChildren)];
			if ($url) {
				var $pseudoElement = document.createElement($html);
				$target.insertAdjacentElement($$position, $pseudoElement);
				$pseudoElement.data = _contentPath;
				addTimer($pseudoElement, $$cssText, Quote.remove($url[1]));
			} else {
				$html = $html.replace(/%2/, $$cssText).replace(/%3/, $content);
				$target.insertAdjacentHTML($$position, $html);
			}
			$target.runtimeStyle[this.position] = null;
		}
	}
});
// constants
PseudoElement.CONTENT = /content\s*:\s*([^;]*)(;|$)/;
PseudoElement.OBJECT = "<object class='ie7_anon %1' ie7_anon width=100% height=0 type=text/x-scriptlet>";
PseudoElement.ANON = "<ie7:! class='ie7_anon %1' ie7_anon style='%2'>%3</ie7:!>";

// -----------------------------------------------------------------------
//  IE7 dynamic pseudo-classes
// -----------------------------------------------------------------------

// constructor
function DynamicPseudoClass($name, $apply) {
	this.name = $name;
	this.apply = $apply;
	this.instances = {};
	ie7CSS.dynamicPseudoClasses[$name] = this;
};
// prototype
Common.specialize({
	// properties
	constructor: DynamicPseudoClass,
//- name: "",
//- apply: null,
//- instances: null,
	// methods
	register: function($instance) {
		// an "instance" is actually an Arguments object
		var $class = $instance[2];
	//-	var $element = $instance[0];
		$instance.id = $class.id + $instance[0].uniqueID;
		if (!this.instances[$instance.id]) {
			var $target = $instance[1], j;
			for (j = 0; j < $target.length; j++) $class.add($target[j]);
			this.instances[$instance.id] = $instance;
		}
	},
	unregister: function($instance) {
		if (this.instances[$instance.id]) {
			var $class = $instance[2];
			var $target = $instance[1], j;
			for (j = 0; j < $target.length; j++) $class.remove($target[j]);
			delete this.instances[$instance.id];
		}
	}
});

// -----------------------------------------------------------------------
// pseudo-classes
// -----------------------------------------------------------------------

ie7CSS.pseudoClasses.toString = function() {
	var $toString = [], $pseudoClass;
	for ($pseudoClass in this) {
		if (this[$pseudoClass].length > 1) $pseudoClass += "\\([^)]*\\)";
		$toString.push($pseudoClass);
	}
	return $toString.join("|");
};

// the "ie7-link" property is set by text contained in the IE7 generated
//  style sheet (the text is stored in the "HEADER")
ie7CSS.pseudoClasses["link"] = function($element) {
	return $element.currentStyle["ie7-link"] == "link";
};

ie7CSS.pseudoClasses["visited"] = function($element) {
	return $element.currentStyle["ie7-link"] == "visited";
};

// -----------------------------------------------------------------------
// dynamic pseudo-classes
// -----------------------------------------------------------------------

var _MOUSEOVER = (appVersion < 5.5) ? "onmouseover" : "onmouseenter";
var _MOUSEOUT = (appVersion < 5.5) ? "onmouseout" : "onmouseleave";

ie7CSS.dynamicPseudoClasses.toString = ie7CSS.pseudoClasses.toString;

var _hover = new DynamicPseudoClass("hover", function($element) {
	var $instance = arguments;
	ie7CSS.addEventHandler($element, _MOUSEOVER, function() {
		_hover.register($instance);
	});
	ie7CSS.addEventHandler($element, _MOUSEOUT, function() {
		_hover.unregister($instance);
	});
});

var _focus = new DynamicPseudoClass("focus", function($element) {
	var $instance = arguments;
	ie7CSS.addEventHandler($element, "onfocus", function() {
		_focus.unregister($instance); // in case it starts with focus
		_focus.register($instance);
	});
	ie7CSS.addEventHandler($element, "onblur", function() {
		_focus.unregister($instance);
	});
	// check the active element for initial state
	if ($element == document.activeElement) {
		_focus.register($instance)
	}
});

/**
  * XXX TODO: find a better way to fix this
  *
  * The two code blocks below have been commented out because they cause
  * JS errors in IE 6.  All they seemingly do is provide support for
  * the :active CSS psuedo-class.
  */

/*
var _active = new DynamicPseudoClass("active", function($element) {
	var $instance = arguments;
	ie7CSS.addEventHandler($element, "onmousedown", function() {
		_active.register($instance);
	});
});

// globally trap the mouseup event (thanks Martijn!)
addEventHandler(document, "onmouseup", function() {
	var $instances = _active.instances, j;
	for (j in $instances) _active.unregister($instances[j]);
	$instances = _hover.instances;
	for (j in $instances)
		if (!$instances[j][0].contains(event.srcElement))
			_hover.unregister($instances[j]);
});
*/

// -----------------------------------------------------------------------
// attribute selectors
// -----------------------------------------------------------------------

ICommon(AttributeSelector);

AttributeSelector.specialize({
	getAttribute: function($name) {
		switch ($name.toLowerCase()) {
			case "class":
				return "e.className.replace(/\\b\\s*ie7_class\\d+/g,'')";
			case "src":
				return "(e.pngSrc||e.src)";
		}
		return this.inherit($name);
	}
});

// -----------------------------------------------------------------------
// encoding
// -----------------------------------------------------------------------

// pseudo-elements can be declared with a double colon
encoder.add(/::/, ":");
// generated content may be unicode encoded
safeString.add(/\\([\da-fA-F]{1,4})/, function($match, $offset) {
	$match = $match[$offset + 1];
	return "\\u" + "0000".slice($match.length) + $match;
});

}); // IE7.addModule

loaded = true;

// -----------------------------------------------------------------------
//  quirks mode patches
// -----------------------------------------------------------------------

/* FAVELET */

// load an external module to patch IE in quirks mode and override the functions above
if (quirksMode) eval(loadFile("ie7-quirks.js", path));

// -----------------------------------------------------------------------
//  initialise
// -----------------------------------------------------------------------

ie7CSS.init();
if (isHTML && ie7HTML) ie7HTML.init();

// this script may be inserted via a favelet so the page may already be loaded
if (complete) IE7.init();
else {
	// if we can load behaviors then use ondocumentready
	documentElement.addBehavior(makePath("ie7-load.htc", path));
	// otherwise this will kick in
	addEventHandler(document, "onreadystatechange", function() {
		// if we are going to wait this long then wem may as well let
		//  window.onload execute first
		if (document.readyState == "complete") setTimeout(IE7.init, 0);
	});
}

// -----------------------------------------------------------------------
//  error handling
// -----------------------------------------------------------------------

} catch ($error) {
	alert("Error [0]: " + $error.description);
} finally {
	// have a beer...
}};
