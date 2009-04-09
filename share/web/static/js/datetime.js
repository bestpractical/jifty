if ( typeof Jifty == "undefined" ) Jifty = { };

Jifty.DateTime = {
    registerDateTimeWidget: function(id) {
        jQuery(id).bind("focus", Jifty.DateTime.toggleDateTime)
                  .bind("blur", Jifty.DateTime.doBlur);

        return true;
    },

    dateRegex: /^(\d{4})\W(\d{2})\W(\d{2})/,
    
    Options: {
        OUT_OF_MONTH_SELECT: true
    },

    toggleDateTime: function() {
        var calId  = "cal_" + this.id;
        var wrapId = calId + "_wrap";
        var wrap   = document.getElementById(wrapId);

        if ( Jifty.DateTime.openDateTime == wrapId ) {
            Jifty.DateTime.hideOpenDateTime();
            return;
        }

        Jifty.DateTime.hideOpenDateTime();
        
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

        var start_weekday = jQuery(this).hasClass('calendar-starts-monday') ? 1 : 0;

        if (Jifty.DateTime.dateRegex.test(this.value) ) {
            var bits = this.value.match(Jifty.DateTime.dateRegex);
            cal = new YAHOO.widget.Calendar(
                calId,
                wrapId,
                {
                    pagedate: bits[2]+"/"+bits[1],
                    selected: bits[2]+"/"+bits[3]+"/"+bits[1],
                    start_weekday: start_weekday
                }
            );
        }
        else {
            cal = new YAHOO.widget.Calendar(
                calId,
                wrapId,
                { start_weekday: start_weekday }
            );
        }

        cal.cfg.applyConfig( Jifty.DateTime.Options );
        cal.cfg.fireQueue();
        
        cal.selectEvent.subscribe( Jifty.DateTime.handleSelect, { input: this, calendar: cal }, true );
        cal.changePageEvent.subscribe( function() { setTimeout( function() { Jifty.DateTime._blurredDateTime = null; }, 75 ) }, null, false );
        
        cal.render();

        Jifty.DateTime.openDateTime = wrapId;
        Jifty.Utils.scrollToShow( wrapId );
        /*Jifty.DateTime.preventStutter = wrapId;*/
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

        jQuery(obj.input).val(year + "-" + month + "-" + day );
        Jifty.DateTime.hideOpenDateTime();
        jQuery(obj.input).next().trigger( 'focus' );

    },

    openDateTime: "",

    hideOpenDateTime: function() {
        if ( Jifty.DateTime.openDateTime && document.getElementById( Jifty.DateTime.openDateTime ) ) {

            /* Get the input's ID */
            var inputId = Jifty.DateTime.openDateTime;
                inputId = inputId.replace(/^cal_/, '');
                inputId = inputId.replace(/_wrap$/, '');

            // XXX: jQuery(Jifty.DateTime.openDateTime).remove() doesn't work for some reason
            var cal = document.getElementById(Jifty.DateTime.openDateTime);
            cal.parentNode.removeChild(cal);

            var input = document.getElementById( inputId );

            /* Reenable canonicalization, and do it */
            Jifty.Form.Element.enableValidation(input);
            Jifty.Form.Element.validate(input);

            Jifty.DateTime.openDateTime = "";
        }
    },

    _doneBlurOnce: false,
    _blurredDateTime: null,
    doBlur: function(ev) {
        if ( Jifty.DateTime.openDateTime && !Jifty.DateTime._doneBlurOnce ) {
            Jifty.DateTime._doneBlurOnce    = true;
            Jifty.DateTime._blurredDateTime = Jifty.DateTime.openDateTime;
            setTimeout( Jifty.DateTime.doBlur, 200 );
            return;
        }
        else if ( Jifty.DateTime._doneBlurOnce
                  && Jifty.DateTime._blurredDateTime == Jifty.DateTime.openDateTime )
        {
            Jifty.DateTime.hideOpenDateTime();
        }
        Jifty.DateTime._doneBlurOnce    = false;
        Jifty.DateTime._blurredDateTime = null;
    }
};

