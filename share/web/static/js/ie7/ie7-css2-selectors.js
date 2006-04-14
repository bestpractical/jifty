/*
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
