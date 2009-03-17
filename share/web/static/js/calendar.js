if ( typeof Jifty == "undefined" ) Jifty = { };

Jifty.Calendar = {
    registerDateWidget: function(id) {
        jQuery(id).bind("focus", Jifty.Calendar.toggleCalendar)
                  .bind("blur", Jifty.Calendar.doBlur);

        return true;
    },

    dateRegex: /^(\d{4})\W(\d{2})\W(\d{2})/,
    
    Options: {
        OUT_OF_MONTH_SELECT: true
    },

    toggleCalendar: function() {
        var calId  = "cal_" + this.id;
        var wrapId = calId + "_wrap";
        var wrap   = document.getElementById(wrapId);

        if ( Jifty.Calendar.openCalendar == wrapId ) {
            Jifty.Calendar.hideOpenCalendar();
            return;
        }

        Jifty.Calendar.hideOpenCalendar();
        
        /* We need to delay Jifty's canonicalization until after we've
           selected a value via the calendar */
        Jifty.Form.Element.disableValidation(this);
        
        wrap = document.createElement("div");
        wrap.setAttribute( "id", wrapId );
        wrap.setAttribute( "class", "select-free" );
        
        wrap.style.position = "absolute";
        wrap.style.left     = Jifty.Utils.findRelativePosX( this ) + "px";
        wrap.style.top      = Jifty.Utils.findRelativePosY( this ) + this.offsetHeight + "px";
        wrap.style.zIndex   = 40;
        
        this.parentNode.insertBefore( wrap, this.nextSibling );

        var cal;
        
        if (Jifty.Calendar.dateRegex.test(this.value) ) {
            var bits = this.value.match(Jifty.Calendar.dateRegex);
            cal = new YAHOO.widget.Calendar( calId,
                                             wrapId,
                                             { pagedate: bits[2]+"/"+bits[1],
                                               selected: bits[2]+"/"+bits[3]+"/"+bits[1],
                                               start_weekday: Jifty.Config.start_weekday }
                                            );
        }
        else {
            cal = new YAHOO.widget.Calendar( calId, wrapId, { start_weekday: Jifty.Config.start_weekday });
        }
        
        cal.cfg.applyConfig( Jifty.Calendar.Options );
        cal.cfg.fireQueue();
        
        cal.selectEvent.subscribe( Jifty.Calendar.handleSelect, { input: this, calendar: cal }, true );
        cal.changePageEvent.subscribe( function() { setTimeout( function() { Jifty.Calendar._blurredCalendar = null; }, 75 ) }, null, false );
        
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

        if (month < 10)
            month = "0" + month;

        if (day < 10)
            day = "0" + day;

        jQuery(obj.input).val(year + "-" + month + "-" + day);
        // Trigger an onchange event for any listeners
        jQuery(obj.input).change();

        Jifty.Calendar.hideOpenCalendar();
    },

    openCalendar: "",

    hideOpenCalendar: function() {
        if ( Jifty.Calendar.openCalendar && document.getElementById( Jifty.Calendar.openCalendar ) ) {

            /* Get the input's ID */
            var inputId = Jifty.Calendar.openCalendar;
                inputId = inputId.replace(/^cal_/, '');
                inputId = inputId.replace(/_wrap$/, '');

            // XXX: jQuery(Jifty.Calendar.openCalendar).remove() doesn't work for some reason
            var cal = document.getElementById(Jifty.Calendar.openCalendar);
            cal.parentNode.removeChild(cal);

            var input = document.getElementById( inputId );

            /* Reenable canonicalization, and do it */
            Jifty.Form.Element.enableValidation(input);
            Jifty.Form.Element.validate(input);

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

