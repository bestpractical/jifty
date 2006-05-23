/**

=head1 NAME

DOM.Events - Event registration abstraction layer

=head1 SYNOPSIS

  JSAN.use("DOM.Events");

  function handleClick(e) {
      e.currentTarget.style.backgroundColor = "#68b";
  }

  DOM.Events.addListener(window, "load", function () {
      alert("The page is loaded.");
  });

  DOM.Events.addListener(window, "load", function () {
      // this listener won't interfere with the first one
      var divs = document.getElementsByTagName("div");
      for(var i=0; i<divs.length; i++) {
          DOM.Events.addListener(divs[i], "click", handleClick);
      }
  });

=head1 DESCRIPTION

This library lets you use a single interface to listen for and handle all DOM events
to reduce browser-specific code branching.  It also helps in dealing with Internet
Explorer's memory leak problem by automatically unsetting all event listeners when
the page is unloaded (for IE only).

=cut

*/

(function () {
	if(typeof DOM == "undefined") DOM = {};
	DOM.Events = {};
	
    DOM.Events.VERSION = "0.02";
	DOM.Events.EXPORT = [];
	DOM.Events.EXPORT_OK = ["addListener", "removeListener"];
	DOM.Events.EXPORT_TAGS = {
		":common": DOM.Events.EXPORT,
		":all": [].concat(DOM.Events.EXPORT, DOM.Events.EXPORT_OK)
	};
	
	// list of event listeners set by addListener
	// offset 0 is null to prevent 0 from being used as a listener identifier
	var listenerList = [null];
	
/**

=head2 Functions

All functions are kept inside the namespace C<DOM.Events> and aren't exported
automatically.

=head3 addListener( S<I<HTMLElement> element,> S<I<string> eventType,>
S<I<Function> handler> S<[, I<boolean> makeCompatible = true] )>

Registers an event listener/handler on an element.  The C<eventType> string should
I<not> be prefixed with "on" (e.g. "mouseover" not "onmouseover"). If C<makeCompatible>
is C<true> (the default), the handler is put inside a wrapper that lets you handle the
events using parts of the DOM Level 2 Events model, even in Internet Explorer (and
behave-alikes). Specifically:

=over

=item *

The event object is passed as the first argument to the event handler, so you don't
have to access it through C<window.event>.

=item *

The event object has the properties C<target>, C<currentTarget>, and C<relatedTarget>
and the methods C<preventDefault()> and C<stopPropagation()> that behave as described
in the DOM Level 2 Events specification (for the most part).

=item *

If possible, the event object for mouse events will have the properties C<pageX> and
C<pageY> that contain the mouse's position relative to the document at the time the
event occurred.

=item *

If you attempt to set a duplicate event handler on an element, the duplicate will
still be added (this is different from the DOM2 Events model, where duplicates are
discarded).

=back

If C<makeCompatible> is C<false>, the arguments are simply passed to the browser's
native event registering facilities, which means you'll have to deal with event
incompatibilities yourself. However, if you don't need to access the event information,
doing it this way can be slightly faster and it gives you the option of unsetting the
handler with a different syntax (see below).

The return value is a positive integer identifier for the listener that can be used to
unregister it later on in your script.

=cut

*/
    
	DOM.Events.addListener = function(elt, ev, func, makeCompatible) {
		var usedFunc = func;
        var id = listenerList.length;
		if(makeCompatible == true || makeCompatible == undefined) {
			usedFunc = makeCompatibilityWrapper(elt, ev, func);
		}
		if(elt.addEventListener) {
			elt.addEventListener(ev, usedFunc, false);
			listenerList[id] = [elt, ev, usedFunc];
			return id;
		}
		else if(elt.attachEvent) {
			elt.attachEvent("on" + ev, usedFunc);
			listenerList[id] = [elt, ev, usedFunc];
			return id;
		}
		else return false;
	};
	
/**

=head3 removeListener( S<I<integer> identifier> )

Unregisters the event listener associated with the given identifier so that it will
no longer be called when the event fires.

  var listener = DOM.Events.addListener(myElement, "mousedown", myHandler);
  // later on ...
  DOM.Events.removeListener(listener);

=head3 removeListener( S<I<HTMLElement> element,> S<I<string> eventType,> S<I<Function> handler )>

This alternative syntax can be also be used to unset an event listener, but it can only
be used if C<makeCompatible> was C<false> when it was set.

=cut

*/

	DOM.Events.removeListener = function() {
		var elt, ev, func;
		if(arguments.length == 1 && listenerList[arguments[0]]) {
			elt  = listenerList[arguments[0]][0];
			ev   = listenerList[arguments[0]][1];
			func = listenerList[arguments[0]][2];
			delete listenerList[arguments[0]];
		}
		else if(arguments.length == 3) {
			elt  = arguments[0];
			ev   = arguments[1];
			func = arguments[2];
		}
		else return;
		
		if(elt.removeEventListener) {
			elt.removeEventListener(ev, func, false);
		}
		else if(elt.detachEvent) {
			elt.detachEvent("on" + ev, func);
		}
	};
	
    var rval;
    
    function makeCompatibilityWrapper(elt, ev, func) {
        return function (e) {
            rval = true;
            if(e == undefined && window.event != undefined)
                e = window.event;
            if(e.target == undefined && e.srcElement != undefined)
                e.target = e.srcElement;
            if(e.currentTarget == undefined)
                e.currentTarget = elt;
            if(e.relatedTarget == undefined) {
                if(ev == "mouseover" && e.fromElement != undefined)
                    e.relatedTarget = e.fromElement;
                else if(ev == "mouseout" && e.toElement != undefined)
                    e.relatedTarget = e.toElement;
            }
            if(e.pageX == undefined) {
                if(document.body.scrollTop != undefined) {
                    e.pageX = e.clientX + document.body.scrollLeft;
                    e.pageY = e.clientY + document.body.scrollTop;
                }
                if(document.documentElement != undefined
                && document.documentElement.scrollTop != undefined) {
                    if(document.documentElement.scrollTop > 0
                    || document.documentElement.scrollLeft > 0) {
                        e.pageX = e.clientX + document.documentElement.scrollLeft;
                        e.pageY = e.clientY + document.documentElement.scrollTop;
                    }
                }
            }
            if(e.stopPropagation == undefined)
                e.stopPropagation = IEStopPropagation;
            if(e.preventDefault == undefined)
                e.preventDefault = IEPreventDefault;
            if(e.cancelable == undefined) e.cancelable = true;
            func(e);
            return rval;
        };
    }
    
    function IEStopPropagation() {
        if(window.event) window.event.cancelBubble = true;
    }
    
    function IEPreventDefault() {
        rval = false;
    }

	function cleanUpIE () {
		for(var i=0; i<listenerList.length; i++) {
			var listener = listenerList[i];
			if(listener) {
				var elt = listener[0];
                var ev = listener[1];
                var func = listener[2];
				elt.detachEvent("on" + ev, func);
			}
		}
        listenerList = null;
	}

	if(!window.addEventListener && window.attachEvent) {
		window.attachEvent("onunload", cleanUpIE);
	}

})();

/**

=head1 SEE ALSO

DOM Level 2 Events Specification,
L<http://www.w3.org/TR/DOM-Level-2-Events/>

Understanding and Solving Internet Explorer Leak Patterns,
L<http://msdn.microsoft.com/library/default.asp?url=/library/en-us/IETechCol/dnwebgen/ie_leak_patterns.asp>

=head1 AUTHOR

Justin Constantino, <F<goflyapig@gmail.com>>.

=head1 COPYRIGHT

  Copyright (c) 2005 Justin Constantino.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public Licence.

=cut

*/