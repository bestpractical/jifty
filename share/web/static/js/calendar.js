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

    dateRegex: /^(\d{4})\W(\d{2})\W(\d{2})/,
    
    Options: {
        NAV_ARROW_LEFT: "/static/images/yui/us/tr/callt.gif",
        NAV_ARROW_RIGHT: "/static/images/yui/us/tr/calrt.gif",
        OOM_SELECT: true
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
                                             { pagedate: bits[2]+"/"+bits[1],
                                               selected: bits[2]+"/"+bits[3]+"/"+bits[1] }
                                            );
        }
        else {
            cal = new YAHOO.widget.Calendar( calId, wrapId );
        }
        
        cal.cfg.applyConfig( Jifty.Calendar.Options );
        cal.cfg.fireQueue();
        
        cal.selectEvent.subscribe( Jifty.Calendar.handleSelect, { event: ev, calendar: cal }, true );
        cal.changePageEvent.subscribe( function() { Jifty.Calendar._blurredCalendar = null; }, null, false );
        
        cal.render();

        Jifty.Calendar.openCalendar = wrapId;
        Jifty.Utils.scrollToShow( wrapId );
        /*Jifty.Calendar.preventStutter = wrapId;*/
    },

    handleSelect: function(type, args, obj) {
        // args = [ [ [yyyy, mm, dd] ] ]
        var year  = args[0][0][0],
            month = args[0][0][1],
            day   = args[0][0][2];

        var input = obj.event.target;
        
        input.value = year + "-" + month + "-" + day;

        Jifty.Calendar.hideOpenCalendar();
        Form.Element.validate( input ); // We can't trigger an onBlur, so canonicalize/validate manually
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

