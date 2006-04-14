/*
	IE7, version 0.9 (alpha) (2005-08-19)
	Copyright: 2004-2005, Dean Edwards (http://dean.edwards.name/)
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/
IE7.addModule("ie7-recalc", function() {

/* ---------------------------------------------------------------------

  This allows refreshing of IE7 style rules. If you modify the DOM
  you can update IE7 by calling document.recalc().

  This should be the LAST module included.

--------------------------------------------------------------------- */

// remove all IE7 classes from an element
$CLASSES = /\sie7_class\d+/g;
function _removeClasses($element) {
	$element.className = $element.className.replace($CLASSES, "");
};

// clear IE7 assigned styles
function _removeStyle($element) {
	$element.runtimeStyle.cssText = "";
};

ie7CSS.specialize({
	// store for elements that have style properties calculated
	elements: {},
	handlers: [],
	// clear IE7 classes and styles
	reset: function() {
		this.removeEventHandlers();
		// reset IE7 classes here
		var $elements = this.elements;
		for (var i in $elements) _removeStyle($elements[i]);
		this.elements = {};
		// reset runtimeStyle here
		if (this.Rule) {
			var $elements = this.Rule.elements;
			for (var i in $elements) _removeClasses($elements[i]);
			this.Rule.elements = {};
		}
	},
	reload: function() {
		ie7CSS.rules = [];
		this.getInlineStyles();
		this.screen.load();
		if (this.print) this.print.load();
		this.refresh();
		this.trash();
	},
	addRecalc: function($propertyName, $test, $handler, $replacement) {
		// call the ancestor method to add a wrapped recalc method
		this.inherit($propertyName, $test, function($element) {
			// execute the original recalc method
			$handler($element);
			// store a reference to this element so we can clear its style later
			ie7CSS.elements[$element.uniqueID] = $element;
		}, $replacement);
	},
	recalc: function() {
		// clear IE7 styles and classes
		this.reset();
		// execute the ancestor method to perform recalculations
		this.inherit();
	},
	addEventHandler: function($element, $type, $handler) {
		$element.attachEvent($type, $handler);
		// store the handler so it can be detached later
		this.handlers.push(arguments);
	},
	removeEventHandlers: function() {
		var $handler;
	 	while ($handler = this.handlers.pop()) {
	 		removeEventHandler($handler[0], $handler[1], $handler[2]);
	 	}
	},
	getInlineStyles: function() {
		// load inline styles
		var $$styleSheets = document.getElementsByTagName("style"), $styleSheet;
		for (var i = $$styleSheets.length - 1; ($styleSheet = $$styleSheets[i]); i--) {
			if (!$styleSheet.disabled && !$styleSheet.ie7) {
				var $cssText = $styleSheet.$cssText || $styleSheet.innerHTML;
				this.styles.push($cssText);
				$styleSheet.$cssText = $cssText;
			}
		}
	},
	trash: function() {
		// trash the old style sheets
		var $styleSheet, i;
		for (i = 0; i < styleSheets.length; i++) {
			$styleSheet = styleSheets[i];
			if (!$styleSheet.ie7 && !$styleSheet.$cssText) {
				$styleSheet.$cssText = $styleSheet.cssText;
			}
		}
		this.inherit();
	},
	getText: function($styleSheet) {
		return $styleSheet.$cssText || this.inherit($styleSheet);
	}
});

// remove event handlers (they eat memory)
addEventHandler(window, "onunload", function() {
 	ie7CSS.removeEventHandlers();
});

if (ie7CSS.Rule) {
	// store all elements with an IE7 class assigned
	ie7CSS.Rule.elements = {};

	ie7CSS.Rule.prototype.specialize({
		add: function($element) {
			// execute the ancestor "add" method
			this.inherit($element);
			// store a reference to this element so we can clear its classes later
			ie7CSS.Rule.elements[$element.uniqueID] = $element;
		}
	});

	// store created pseudo elements
	ie7CSS.PseudoElement.hash = {};

	ie7CSS.PseudoElement.prototype.specialize({
		create: function($target) {
			var $key = this.selector + ":" + $target.uniqueID;
			if (!ie7CSS.PseudoElement.hash[$key]) {
				ie7CSS.PseudoElement.hash[$key] = true;
				this.inherit($target);
			}
		}
	});
}

if (isHTML && ie7HTML) {
	ie7HTML.specialize({
		elements: {},
		addRecalc: function($selector, $handler) {
			// call the ancestor method to add a wrapped recalc method
			this.inherit($selector, function($element) {
				if (!ie7HTML.elements[$element.uniqueID]) {
					// execute the original recalc method
					$handler($element);
					// store a reference to this element so that
					//  it is not "fixed" again
					ie7HTML.elements[$element.uniqueID] = $element;
				}
			});
		}
	});
}

// allow refreshing of IE7 fixes
document.recalc = function(reload) {
	if (ie7CSS.screen) {
		if (reload) ie7CSS.reload();
		recalc();
	}
};

});
