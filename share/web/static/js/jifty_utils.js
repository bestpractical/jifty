
if (typeof Jifty == "undefined") Jifty = { };

Jifty.Utils = {};

jQuery.extend(Jifty.Utils, {
    buttonToLink: function(e) {
        var link = document.createElement("a");
        link.setAttribute("href","#");
        link.setAttribute("name",e.getAttribute("name"));

        var form = Jifty.Form.Element.getForm(e);
        var onclick = e.getAttribute("onclick");

        /* Simple buttons that don't use any JS need us to create an onclick
           for them that makes sure the original button's name gets passed
           and the form submitted normally (without any Ajax-ness)
        */
        if ( !onclick ) {
            jQuery( link ).click(function(ev) {
                var a = ev.target;
                var hidden = document.createElement("input");
                hidden.setAttribute("type", "hidden");
                hidden.setAttribute("name", a.getAttribute("name"));
                a["virtualform"].appendChild( hidden );
                if ( a["virtualform"].onsubmit )
                    a["virtualform"].onsubmit();
                a["virtualform"].submit();
            });
        }
        link.setAttribute("onclick", onclick);
        link.setAttribute("title", e.getAttribute("title"));

        link.className = e.className;
        link["virtualform"] = form;
        link.appendChild(document.createTextNode(e.getAttribute("value")));

        e.parentNode.insertBefore(link, e.nextSibling);
        e.parentNode.removeChild(e);
        return link;
    },

    updateParentField: function(field, value) {
        if (window.opener) {
            window.opener.document.getElementById(field).value = value;
            window.close();
        }
    },

    createCalendarLink: function(id) {
        return Jifty.Calendar.registerDateWidget( id );
    },

    createDateTimeLink: function(id) {
        return Jifty.DateTime.registerDateTimeWidget( id );
    },

    /* From http://blog.firetree.net/2005/07/04/javascript-find-position/ */
    findPosX: function(obj)
    {
      var curleft = 0;
      if(obj.offsetParent)
          while(1) 
          {
            curleft += obj.offsetLeft;
            if(!obj.offsetParent)
              break;
            obj = obj.offsetParent;
          }
      else if(obj.x)
          curleft += obj.x;
      return curleft;
    },

    findPosY: function(obj)
    {
      var curtop = 0;
      if(obj.offsetParent)
          while(1)
          {
            curtop += obj.offsetTop;
            if(!obj.offsetParent)
              break;
            obj = obj.offsetParent;
          }
      else if(obj.y)
          curtop += obj.y;
      return curtop;
    },

    findRelativePosX: function(e) {
        var parent  = e.parentNode;
        var parentx = 0;
        
        while ( parent ) {
            if ( !parent.style ) break;
            
            var pos = jQuery(parent).css("position");
            if ( pos == "relative" || pos == "absolute" ) {
                parentx = Jifty.Utils.findPosX( parent );
                break;
            }
            parent = parent.parentNode;
        }
        
        return Jifty.Utils.findPosX( e ) - parentx;
    },

    findRelativePosY: function(e) {
        var parent  = e.parentNode;
        var parenty = 0;
        
        while ( parent ) {
            if ( !parent.style ) break;
            
            var pos = jQuery(parent).css("position");
            if ( pos == "relative" || pos == "absolute" ) {
                parenty = Jifty.Utils.findPosY( parent );
                break;
            }
            parent = parent.parentNode;
        }
        
        return Jifty.Utils.findPosY( e ) - parenty;
    },

    isMSIE: false,

    _browser: null,
    browser: function() {
        if ( Jifty.Utils._browser ) return Jifty.Utils._browser;

        if ( Jifty.Utils.isMSIE ) {
            Jifty.Utils._browser = "msie";
            return "msie";
        }

        var browser = "unknown";
        
        if      ( Jifty.Utils._checkUAFor("konqueror"))   browser = "konqueror";
        else if ( Jifty.Utils._checkUAFor("safari"))      browser = "safari";
        else if ( Jifty.Utils._checkUAFor("omniweb"))     browser = "omniweb";
        else if ( Jifty.Utils._checkUAFor("opera"))       browser = "opera";
        else if ( Jifty.Utils._checkUAFor("webtv"))       browser = "webtv";
        else if ( Jifty.Utils._checkUAFor("icab"))        browser = "icab";
        else if ( Jifty.Utils._checkUAFor("msie"))        browser = "msie";
        else if ( !Jifty.Utils._checkUAFor("compatible")) browser = "mozilla";
        
        Jifty.Utils._browser = browser;
        return browser;
    },

    _ua: navigator.userAgent.toLowerCase(),
    _checkUAFor: function(str) {
        return Jifty.Utils._ua.indexOf( str ) + 1;
    },

    findScreenHeight: function() {
        if ( window.innerHeight ) {
            return window.innerHeight;
        }
        else {
            if ( document.documentElement.clientHeight ) {
                return document.documentElement.clientHeight;
            }
            else {
                if ( document.body.clientHeight ) {
                    return document.body.clientHeight;
                }
            }
        }
    },

    getScrollTop: function() {
        if (document.body && document.body.scrollTop)
            return document.body.scrollTop;
        if (document.documentElement && document.documentElement.scrollTop)
            return document.documentElement.scrollTop;
        if (window.pageYOffset)
            return window.pageYOffset;
        return 0; 
    },

    scrollToShow: function(id) {
        var ul        = Jifty.$(id);
        var y         = Jifty.Utils.findPosY( ul ) + ul.offsetHeight + 10;
        var scrollTop = Jifty.Utils.getScrollTop();
        var screen    = Jifty.Utils.findScreenHeight() + scrollTop;
        var diff      = y - screen;
        
        if ( diff > 0 )
             Jifty.SmoothScroll.scrollTo( scrollTop + diff );
    },

    stripScripts: function(str) {
        return str.replace(/<script(.|\s)*?\/script>/g, "");
    },

    encodeEntities: function (str) {
        return jQuery("<div />").text(str).html();
    }
});

/* This sets Jifty.Utils.isMSIE to true in IE */
/* @cc_on
    Jifty.Utils.isMSIE = true;
@*/

