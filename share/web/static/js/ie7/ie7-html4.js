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
