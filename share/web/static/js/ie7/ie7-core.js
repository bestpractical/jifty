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
