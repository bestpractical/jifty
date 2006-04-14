/*
	IE7, version 0.9 (alpha) (2005-08-19)
	Copyright: 2004-2005, Dean Edwards (http://dean.edwards.name/)
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/

IE7.addModule("ie7-css-strict", function() {

// requires another module
if (!modules["ie7-css2-selectors"]) return;

// -----------------------------------------------------------------------
//  IE7 StyleSheet class
// -----------------------------------------------------------------------
StyleSheet.prototype.specialize({
	// override the createRule method - ALL rules are now IE7 rules
	parse: function() {
		this.inherit();
		// there is no decoding as such any more as all rules are IE7 rules.
		//  we'll sort the rules and build a new style sheet
		var $rules = [].concat(this.rules);
		$rules.sort(ie7CSS.Rule.compare);
		this.cssText = $rules.join("\n");
	},
	// override the createRule method - ALL rules are now IE7 rules
	createRule: function($selector, $cssText) {
		var $match;
		if ($match = $selector.match(ie7CSS.PseudoElement.MATCH))
			return new ie7CSS.PseudoElement($match[1], $match[2], $cssText);
		else if ($match = $selector.match(ie7CSS.DynamicRule.MATCH))
			return new ie7CSS.DynamicRule($selector, $match[1], $match[2], $match[3], $cssText);
		else
			return new ie7CSS.Rule($selector, $cssText);
	}
});

// -----------------------------------------------------------------------
//  IE7 CSS
// -----------------------------------------------------------------------

ie7CSS.specialize({
	apply: function() {
		this.inherit();
		this.Rule.MATCH = /([^{}]+)(\{[^{}]*\})/g;
	}
});

// sort function
ie7CSS.Rule.compare = function($rule1, $rule2) {
	return $rule1.specificity - $rule2.specificity;
};

// calculate specificity for a given selector
var $NONE = [], $ID = /#/g, $CLASS = /[.:\[]/g, $TAG = /^\w|[\s>+~]\w/g;
ie7CSS.Rule.score = function($selector) {
	return ($selector.match($ID)||$NONE).length * 10000 +
		($selector.match($CLASS)||$NONE).length * 100 +
		($selector.match($TAG)||$NONE).length;
};

ie7CSS.Rule.simple = function() {return ""};

ie7CSS.Rule.prototype.specialize({
	specificity: 0,
	init: function() {
		// calculate specificity (rules are sorted on this value)
		this.specificity = ie7CSS.Rule.score(this.selector);
	}
});

});
