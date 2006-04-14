/*
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

});