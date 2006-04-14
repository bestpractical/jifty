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

});