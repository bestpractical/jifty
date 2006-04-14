/*
	IE7, version 0.9 (alpha) (2005-08-19)
	Copyright: 2004-2005, Dean Edwards (http://dean.edwards.name/)
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/

IE7.addModule("ie7-quirks", function() {

/* ---------------------------------------------------------------------
  This module is loaded automatically by IE7.
--------------------------------------------------------------------- */

if (quirksMode) {

// -----------------------------------------------------------------------
//  Named font sizes
// -----------------------------------------------------------------------

var $FONT_SIZES = "xx-small,x-small,small,medium,large,x-large,xx-large".split(",");
for (var i = 0; i < $FONT_SIZES.length; i++) {
	$FONT_SIZES[$FONT_SIZES[i]] = $FONT_SIZES[i - 1] || "0.67em";
}
ie7CSS.addFix(new RegExp("(font(-size)?\\s*:\\s*)([\\w\\-\\.]+)"), function($match, $offset) {
	return $match[$offset + 1] + ($FONT_SIZES[$match[$offset + 3]] || $match[$offset + 3]);
});

// -----------------------------------------------------------------------
//  IE5.x (getPixelValue mostly)
// -----------------------------------------------------------------------

// IE5.x specific
if (appVersion < 6) {

	var $NEGATIVE = /^\-/, $LENGTH = /(em|ex)$/i;
	var EM = /em$/i, EX = /ex$/i;

	function _getFontScale($element) {
		var $scale = 1;
		_tmp.style.fontFamily = $element.currentStyle.fontFamily;
		_tmp.style.lineHeight = $element.currentStyle.lineHeight;
		//_tmp.style.fontSize = "";
		while ($element != body) {
			var $fontSize = $element.currentStyle["ie7-font-size"];
			if ($fontSize) {
				if (EM.test($fontSize)) $scale *= parseFloat($fontSize);
				else if (PERCENT.test($fontSize)) $scale *= (parseFloat($fontSize) / 100);
				else if (EX.test($fontSize)) $scale *= (parseFloat($fontSize) / 2);
				else {
					_tmp.style.fontSize = $fontSize;
					return 1;
				}
			}
			$element = $element.parentElement;
		}
		return $scale;
	};

	var _tmp = createTempElement();

	getPixelValue = function($element, $value) {
		if (PIXEL.test($value||0)) return parseInt($value||0);
		var scale = $NEGATIVE.test($value)? -1 : 1;
		if ($LENGTH.test($value)) scale *= _getFontScale($element);
		_tmp.style.width = (scale < 0) ? $value.slice(1) : $value;
		body.appendChild(_tmp);
		// retrieve pixel width
		$value = scale * _tmp.offsetWidth;
		// remove the temporary $element
		_tmp.removeNode();
		return parseInt($value);
	};

	// we need to preserve font-sizes as IE makes a bad job of it
	HEADER = HEADER.replace(/(font(-size)?\s*:\s*([^\s;}\/]*))/gi, "ie7-font-size:$3;$1");

	// cursor:pointer (IE5.x)
	ie7CSS.addFix(/cursor\s*:\s*pointer/, "cursor:hand");
	// display:list-item (IE5.x)
	ie7CSS.addFix(/display\s*:\s*list-item/, "display:block");
}

// -----------------------------------------------------------------------
//  margin:auto
// -----------------------------------------------------------------------

function getPaddingWidth($element) {
	return getPixelValue($element, $element.currentStyle.paddingLeft) +
		getPixelValue($element, $element.currentStyle.paddingRight);
};

function _fixMargin($element) {
	if (appVersion < 5.5 && ie7Layout) ie7Layout.boxSizing($element.parentElement);
	var $parent = $element.parentElement;
	var $margin = $parent.offsetWidth - $element.offsetWidth - getPaddingWidth($parent);
	var $autoRight = ($element.currentStyle["ie7-margin"] && $element.currentStyle.marginRight == "auto") ||
		$element.currentStyle["ie7-margin-right"] == "auto";
	switch ($parent.currentStyle.textAlign) {
		case "right":
			$margin = ($autoRight) ? parseInt($margin / 2) : 0;
			$element.runtimeStyle.marginRight = parseInt($margin) + "px";
			break;
		case "center":
			if ($autoRight) $margin = 0;
		default:
			if ($autoRight) $margin = parseInt($margin / 2);
			$element.runtimeStyle.marginLeft = parseInt($margin) + "px";
	}
};

ie7CSS.addRecalc("margin(-left|-right)?", "[^};]*auto", function($element) {
	if (register(_fixMargin, $element,
		$element.parentElement &&
		$element.currentStyle.display == "block" &&
		$element.currentStyle.marginLeft == "auto" &&
	    $element.currentStyle.position != "absolute")) {
			_fixMargin($element);
	}
});

addResize(function() {
	for (var i in _fixMargin.elements) {
		$element = _fixMargin.elements[i];
    	$element.runtimeStyle.marginLeft =
    	$element.runtimeStyle.marginRight = "";
		_fixMargin($element);
	}
});

}}); // addModule
