/*
	IE7, version 0.9 (alpha) (2005-08-19)
	Copyright: 2004-2005, Dean Edwards (http://dean.edwards.name/)
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/

IE7.addModule("ie7-css3-selectors", function() {

/*
	cssQuery, version 2.0.2 (2005-08-19)
	Copyright: 2004-2005, Dean Edwards (http://dean.edwards.name/)
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/

/* Thanks to Bill Edney */

cssQuery.addModule("css-level3", function() {

// -----------------------------------------------------------------------
// selectors
// -----------------------------------------------------------------------

// indirect sibling selector
selectors["~"] = function($results, $from, $tagName, $namespace) {
	var $element, i;
	for (i = 0; ($element = $from[i]); i++) {
		while ($element = nextElementSibling($element)) {
			if (compareTagName($element, $tagName, $namespace))
				$results.push($element);
		}
	}
};

// -----------------------------------------------------------------------
// pseudo-classes
// -----------------------------------------------------------------------

// I'm hoping these pseudo-classes are pretty readable. Let me know if
//  any need explanation.

pseudoClasses["contains"] = function($element, $text) {
	$text = new RegExp(regEscape(getText($text)));
	return $text.test(getTextContent($element));
};

pseudoClasses["root"] = function($element) {
	return $element == getDocument($element).documentElement;
};

pseudoClasses["empty"] = function($element) {
	var $node, i;
	for (i = 0; ($node = $element.childNodes[i]); i++) {
		if (thisElement($node) || $node.nodeType == 3) return false;
	}
	return true;
};

pseudoClasses["last-child"] = function($element) {
	return !nextElementSibling($element);
};

pseudoClasses["only-child"] = function($element) {
	$element = $element.parentNode;
	return firstElementChild($element) == lastElementChild($element);
};

pseudoClasses["not"] = function($element, $selector) {
	var $negated = cssQuery($selector, getDocument($element));
	for (var i = 0; i < $negated.length; i++) {
		if ($negated[i] == $element) return false;
	}
	return true;
};

pseudoClasses["nth-child"] = function($element, $arguments) {
	return nthChild($element, $arguments, previousElementSibling);
};

pseudoClasses["nth-last-child"] = function($element, $arguments) {
	return nthChild($element, $arguments, nextElementSibling);
};

pseudoClasses["target"] = function($element) {
	return $element.id == location.hash.slice(1);
};

// UI element states

pseudoClasses["checked"] = function($element) {
	return $element.checked;
};

pseudoClasses["enabled"] = function($element) {
	return $element.disabled === false;
};

pseudoClasses["disabled"] = function($element) {
	return $element.disabled;
};

pseudoClasses["indeterminate"] = function($element) {
	return $element.indeterminate;
};

// -----------------------------------------------------------------------
//  attribute selector tests
// -----------------------------------------------------------------------

AttributeSelector.tests["^="] = function($attribute, $value) {
	return "/^" + regEscape($value) + "/.test(" + $attribute + ")";
};

AttributeSelector.tests["$="] = function($attribute, $value) {
	return "/" + regEscape($value) + "$/.test(" + $attribute + ")";
};

AttributeSelector.tests["*="] = function($attribute, $value) {
	return "/" + regEscape($value) + "/.test(" + $attribute + ")";
};

// -----------------------------------------------------------------------
//  nth child support (Bill Edney)
// -----------------------------------------------------------------------

function nthChild($element, $arguments, $traverse) {
	switch ($arguments) {
		case "n": return true;
		case "even": $arguments = "2n"; break;
		case "odd": $arguments = "2n+1";
	}

	var $$children = childElements($element.parentNode);
	function _checkIndex($index) {
		var $index = ($traverse == nextElementSibling) ? $$children.length - $index : $index - 1;
		return $$children[$index] == $element;
	};

	//	it was just a number (no "n")
	if (!isNaN($arguments)) return _checkIndex($arguments);

	$arguments = $arguments.split("n");
	var $multiplier = parseInt($arguments[0]);
	var $step = parseInt($arguments[1]);

	if ((isNaN($multiplier) || $multiplier == 1) && $step == 0) return true;
	if ($multiplier == 0 && !isNaN($step)) return _checkIndex($step);
	if (isNaN($step)) $step = 0;

	var $count = 1;
	while ($element = $traverse($element)) $count++;

	if (isNaN($multiplier) || $multiplier == 1)
		return ($traverse == nextElementSibling) ? ($count <= $step) : ($step >= $count);

	return ($count % $multiplier) == $step;
};

}); // addModule
var firstElementChild = cssQuery.valueOf("firstElementChild");

// -----------------------------------------------------------------------
// pseudo-classes
// -----------------------------------------------------------------------

ie7CSS.pseudoClasses["root"] = function($element) {
	return ($element == viewport) || (!isHTML && $element == firstElementChild(body));
};

// -----------------------------------------------------------------------
// dynamic pseudo-classes
// -----------------------------------------------------------------------

// :checked
var _checked = new ie7CSS.DynamicPseudoClass("checked", function($element) {
	if (typeof $element.checked != "boolean") return;
	var $instance = arguments;
	ie7CSS.addEventHandler($element, "onpropertychange", function() {
		if (event.propertyName == "checked") {
			if ($element.checked) _checked.register($instance);
			else _checked.unregister($instance);
		}
	});
	// check current checked state
	if ($element.checked) _checked.register($instance);
});

// :enabled
var _enabled = new ie7CSS.DynamicPseudoClass("enabled", function($element) {
	if (typeof $element.disabled != "boolean") return;
	var $instance = arguments;
	ie7CSS.addEventHandler($element, "onpropertychange", function() {
		if (event.propertyName == "disabled") {
			if (!$element.isDisabled) _enabled.register($instance);
			else _enabled.unregister($instance);
		}
	});
	// check current disabled state
	if (!$element.isDisabled) _enabled.register($instance);
});

// :disabled
var _disabled = new ie7CSS.DynamicPseudoClass("disabled", function($element) {
	if (typeof $element.disabled != "boolean") return;
	var $instance = arguments;
	ie7CSS.addEventHandler($element, "onpropertychange", function() {
		if (event.propertyName == "disabled") {
			if ($element.isDisabled) _disabled.register($instance);
			else _disabled.unregister($instance);
		}
	});
	// check current disabled state
	if ($element.isDisabled) _disabled.register($instance);
});

// :indeterminate (Kevin Newman)
var _indeterminate = new ie7CSS.DynamicPseudoClass("indeterminate", function($element) {
	if (typeof $element.indeterminate != "boolean") return;
	var $instance = arguments;
	ie7CSS.addEventHandler($element, "onpropertychange", function() {
		if (event.propertyName == "indeterminate") {
			if ($element.indeterminate) _indeterminate.register($instance);
			else _indeterminate.unregister($instance);
		}
	});
	ie7CSS.addEventHandler($element, "onclick", function() {
		_indeterminate.unregister($instance);
	});
	// clever Kev says no need to check this up front
});

// :target
var _target = new ie7CSS.DynamicPseudoClass("target", function($element) {
	var $instance = arguments;
	// if an element has a tabIndex then it can become "active".
	//  The default is zero anyway but it works...
	if (!$element.tabIndex) $element.tabIndex = 0;
	// this doesn't detect the back button. I don't know how to do that :-(
	ie7CSS.addEventHandler(document, "onpropertychange", function() {
		if (event.propertyName == "activeElement") {
			if ($element.id == location.hash.slice(1)) _target.register($instance);
			else _target.unregister($instance);
		}
	});
	// check the current location
	if ($element.id == location.hash.slice(1)) _target.register($instance);
});

// -----------------------------------------------------------------------
// encoding
// -----------------------------------------------------------------------

// CSS namespaces
decoder.add(/\|/, "\\:");

}); // IE7.addModule
