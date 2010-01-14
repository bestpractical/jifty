/*

  This file is intended for you to add application-specific Javascript
  behaviours. Behaviour lets you apply javascript to elements of the DOM using
  CSS selectors. A simple example:

  var myrules = {
      "h2.rounded": function(element) {
          doRounding(element);
      }
  };
  
  Behaviour.register(myrules);

  In general, you'll rarely if ever have to worry about calling
  Behaviour.apply() yourself -- Jifty will take care of it on DOM load
  and on any AJAX updates that it does.


  Some Notes About Writing Behaviours
  ===================================

  * Jifty's Behaviour.js uses the jQuery[1] library to do our DOM
    lookups by CSS selector. jQuery is very powerful, but can be
    slower as the DOM size grows. For best performance, follow these
    guidelines when writing behaviours, whenever possible:

    * Prefer selectors that begin with '#id'. jQuery will use
      document.getElementByID to get the ID in question, meaning we
      only have to search a small fragment of the DOM by hand

    * Barring that, prefer selectors of the form 'element.class' over
      simply '.class' selectors. This lets us filter for that element
      specifically using DOM calls, again hugely reducing the amount
      of DOM walking we have to do. 

    [1] http://jquery.com


  * Behaviour has something of a reputation for leaking memory. The
    reason for this is a common idiom used in constructing
    behaviours. Code like:

    Behaviour.register({
        'a.help': function(e) {
            e.onclick = function() {
                openInHelpWindow(this);
                return false;
            }
        }
    });

    will leak memory in Internet Explorer, thanks to how IE handles
    garbage collection (See the footnote for details). To avoid this,
    you can use one of the following two idioms:

    (a) Use jQuery to bind events like onclick:

    Behaviour.register({
        'a.help': function(e) {
            jQuery(e).click(function() {
                openInHelpWindow(this);
                return false;
            });
        }
    });

    (b) Declare the onclick function elsewhere:

    function openHelpLink() {
        openInHelpWindow(this);
        return false;
    }
    
    Behaviour.register({
        'a.help': function(e) {
            e.onclick = openHelpLink;
        }
    });

    (c) Set the element to 'null' at the end of the Behaviour function:

    Behaviour.register({
        'a.help': function(e) {
            e.onclick = function() {
                openInHelpWindow(this);
                return false;
            }
            e = null;
        }
    });

  * Jifty has recently gained built-in support for limited profiling
    of Behaviours via the ProfileBehaviour plugin (in the Jifty svn
    tree). After installing the module, add it to your config.yml,
    using, e.g:

      Plugins:
        - ProfileBehaviour: {}

    Once you do this, all pages in your application should have a
    ``Behaviour profile'' link at the bottom left hand corner of the
    screen. Click it to get a breakdown of how much time your
    javascript is spending in which behaviours, and whether the time
    is spent in looking up the CSS Selector you passed (jQuery
    time), or in applying the Behaviour function (function time).
    

    ** Footnote **

    The reason that code leaks in IE is that Internet Explorer uses
    reference counting to manage memory in its Javascript engine,
    which means that circular references are never freed. When you
    write this code:

    Behaviour.register({
        'a.help': function(e) {         // <-- FUNCTION A
            e.onclick = function() {    // <-- FUNCTION B
                openInHelpWindow(this);
                return false;
            }
        }
    });

    You are in fact creating a circular data structure because
    function `B', when it is created, stores a reference to the
    environment in which it was created, which includes the variable
    `e'. `e', however, also references function `B' through its
    `onclick' property, and this a circular chain of references is
    created, which IE will never garbage collect.

    Solution (b) addresses this by moving function `b' outside of the
    scope where `e' is defined. Solution (c) addresses it by setting
    `e' to null in the environment around `b', which means that that
    environment no longer contains a reference to that DOM node, and
    the loop no longer exists.

*/

