JSAN.use("DOM.Events");

if ( typeof Jifty == "undefined" ) Jifty = { };

Jifty.Calendar = {
    registerDateWidget: function(id) {
        var input = $(id);
        
        if ( !input ) return false;

        DOM.Events.addListener( input, "focus", Jifty.Calendar.toggleCalendar );
        DOM.Events.addListener( input, "blur", Jifty.Calendar.doBlur );
        return true;
    },

    dateFormat: "Y-m-d",

    Options: {
        NAV_ARROW_LEFT: "/static/images/yui/us/tr/callt.gif",
        NAV_ARROW_RIGHT: "/static/images/yui/us/tr/calrt.gif"
    },

    toggleCalendar: function(ev) {
        var calId  = "cal_" + ev.target.id;
        var wrapId = calId + "_wrap";
        var wrap   = $(wrapId);
        var input  = ev.target;

        if ( Jifty.Calendar.openCalendar == wrapId ) {
            Jifty.Calendar.hideOpenCalendar();
            return;
        }

        Jifty.Calendar.hideOpenCalendar();
        
        /* We need to delay Jifty's canonicalization until after we've
           selected a value via the calendar */
        input["_onblur"] = input.onblur;
        input.onblur     = null;
        
        if ( wrap ) {
            wrap.style.display = "block";
            Jifty.Calendar.openCalendar = wrapId;
            Jifty.Utils.scrollToShow( wrapId );
            return;
        }

        wrap = document.createElement("div");
        wrap.setAttribute( "id", wrapId );
        
        wrap.style.position = "absolute";
        wrap.style.left     = Jifty.Utils.findRelativePosX( input ) + "px";
        wrap.style.top      = Jifty.Utils.findRelativePosY( input ) + input.offsetHeight + "px";
        wrap.style.zIndex   = 40;
        
        input.parentNode.insertBefore( wrap, input.nextSibling );

        var cal;
        
        if ( /^(\d{4})\W(\d{2})\W(\d{2})/.test(input.value) ) {
            var bits = input.value.match(/^(\d{4})\W(\d{2})\W(\d{2})/);
            cal = new YAHOO.widget.Calendar( calId,
                                             wrapId,
                                             bits[2]+"/"+bits[1],
                                             bits[2]+"/"+bits[3]+"/"+bits[1]
                                            );
        }
        else {
            cal = new YAHOO.widget.Calendar( calId, wrapId );
        }
        

        cal["customConfig"] = function(){ 
            for (i in Jifty.Calendar.Options) {
                this.Options[i] = Jifty.Calendar.Options[i];
            } 
        };

        cal["onSelect"] = function() {
            input.value = cal.getSelectedDates()[0].formatDate(Jifty.Calendar.dateFormat);
            Jifty.Calendar.hideOpenCalendar();
        };

        cal["_onChangePage"] = cal["onChangePage"];
        cal["onChangePage"]  = function() {
            Jifty.Calendar._blurredCalendar = null;
            cal["_onChangePage"]();
        };
        
        cal.setupConfig();
        cal.render();
        
        Jifty.Calendar.openCalendar = wrapId;
        Jifty.Utils.scrollToShow( wrapId );
        /*Jifty.Calendar.preventStutter = wrapId;*/
    },

    openCalendar: "",

    hideOpenCalendar: function() {
        if ( Jifty.Calendar.openCalendar && $( Jifty.Calendar.openCalendar ) ) {
            $( Jifty.Calendar.openCalendar ).style.display = "none";

            /* Get the input's ID */
            var inputId = Jifty.Calendar.openCalendar;
                inputId = inputId.replace(/^cal_/, '');
                inputId = inputId.replace(/_wrap$/, '');

            var input = $( inputId );

            /* Restore the original onblur */
            input.onblur     = input["_onblur"];
            input["_onblur"] = null;
            
            Jifty.Calendar.openCalendar = "";
        }
    },

    _doneBlurOnce: false,
    _blurredCalendar: null,
    doBlur: function(ev) {
        if ( Jifty.Calendar.openCalendar && !Jifty.Calendar._doneBlurOnce ) {
            Jifty.Calendar._doneBlurOnce    = true;
            Jifty.Calendar._blurredCalendar = Jifty.Calendar.openCalendar;
            setTimeout( Jifty.Calendar.doBlur, 200 );
            return;
        }
        else if ( Jifty.Calendar._doneBlurOnce
                  && Jifty.Calendar._blurredCalendar == Jifty.Calendar.openCalendar )
        {
            Jifty.Calendar.hideOpenCalendar();
        }
        Jifty.Calendar._doneBlurOnce    = false;
        Jifty.Calendar._blurredCalendar = null;
    }
};

/*DOM.Events.addListener( window, "click", Jifty.Calendar.hideOpenCalendar );*/

