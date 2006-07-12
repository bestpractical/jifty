
if (typeof Jifty == "undefined") Jifty = { };

Jifty.Utils = {
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
            
            var pos = Element.getStyle( parent, "position" );
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
            
            var pos = Element.getStyle( parent, "position" );
            if ( pos == "relative" || pos == "absolute" ) {
                parenty = Jifty.Utils.findPosY( parent );
                break;
            }
            parent = parent.parentNode;
        }
        
        return Jifty.Utils.findPosY( e ) - parenty;
    },

    isMSIE: false,

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
    }
};

/* This sets Jifty.Utils.isMSIE to true in IE
    @cc_on
    @if ( @_win32 )
        Jifty.Utils.isMSIE = true;
    @end
*/

