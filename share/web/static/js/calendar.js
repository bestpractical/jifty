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
    dateRegex: /^(\d{4})\W(\d{2})\W(\d{2})/,
    
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
        Form.Element.disableValidation(input);
        
        wrap = document.createElement("div");
        wrap.setAttribute( "id", wrapId );
        wrap.setAttribute( "className", "select-free" );
        
        wrap.style.position = "absolute";
        wrap.style.left     = Jifty.Utils.findRelativePosX( input ) + "px";
        wrap.style.top      = Jifty.Utils.findRelativePosY( input ) + input.offsetHeight + "px";
        wrap.style.zIndex   = 40;
        
        input.parentNode.insertBefore( wrap, input.nextSibling );

        var cal;
        
        if (Jifty.Calendar.dateRegex.test(input.value) ) {
            var bits = input.value.match(Jifty.Calendar.dateRegex);
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
            Form.Element.validate(input); // We can't trigger an onBlur, so canonicalize/validate manually
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
        /* IE fix */
        if ( navigator.userAgent.toLowerCase().indexOf("msie") >= 0 && navigator.appVersion.indexOf("MSIE 7") < 0 ) { 
            wrap.appendChild(document.createElement("iframe"));
        }
    },

    openCalendar: "",

    hideOpenCalendar: function() {
        if ( Jifty.Calendar.openCalendar && $( Jifty.Calendar.openCalendar ) ) {

            /* Get the input's ID */
            var inputId = Jifty.Calendar.openCalendar;
                inputId = inputId.replace(/^cal_/, '');
                inputId = inputId.replace(/_wrap$/, '');

            Element.remove(Jifty.Calendar.openCalendar);

            var input = $( inputId );

            /* Reenable canonicalization */
            Form.Element.enableValidation(input);

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

