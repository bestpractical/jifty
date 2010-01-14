if (typeof Jifty == "undefined") Jifty = { };

function jifty_context_menu_prepExpandButton(e) {
    e.onmousedown = function() { this.onfocus = this.blur };
    e.onmouseup   = function() { this.onfocus = window.clientInformation ? null : window.undefined };
    e = null;	// Don't leak in IE
}

Jifty.ContextMenu = {
    behaviourRules: {
        "ul.menu li.toplevel span.expand a": jifty_context_menu_prepExpandButton,
        "ul.context_menu li.toplevel span.expand a": jifty_context_menu_prepExpandButton
    },

    currently_open:  "",
    prevent_stutter: "",

    getParentListItem: function(ul) {
        /* XXX TODO: Put this in the onclick handler? */
        return ul.parentNode;
    },

    hideshow: function(id) {
        var ul = document.getElementById(id);

        Jifty.ContextMenu.prevent_stutter = id;

        if ( ul.style.display == "block" )
            Jifty.ContextMenu.hide(id);
        else
            Jifty.ContextMenu.show(id);
    },

    hide: function(id) {
        var ul = document.getElementById(id);

        if ( ul ) {
            var li = Jifty.ContextMenu.getParentListItem(ul);
            jQuery(li).removeClass("open").addClass("closed");
            
            ul.style.display = "none";
        }
        Jifty.ContextMenu.currently_open = "";
    },

    show: function(id) {
        var ul = document.getElementById(id);
        if ( !ul ) return;
        
        if (   Jifty.ContextMenu.currently_open
            && Jifty.ContextMenu.currently_open != ul.id )
        {
            Jifty.ContextMenu.hide(Jifty.ContextMenu.currently_open);
        }
    
        var li = Jifty.ContextMenu.getParentListItem(ul);

        jQuery(ul).addClass("dropdown_menu");
        ul.style.position = "absolute";
        ul.style.width    = "12em";
        
        /* Use position: relative based positioning for every browser
           but IE, which needs to use absolute positioning */
        if ( Jifty.Utils.isMSIE ) {
            if ( ul.style.position == "" ) {
                var x = Jifty.Utils.findPosX( li );
                var y = Jifty.Utils.findPosY( li ) + li.offsetHeight;
                
                ul.style.left = x + "px";
                ul.style.top  = y + "px";
            }
        }
        else {
            ul.style.left     = "-1px";
            ul.style.top      = li.offsetHeight - 2 + "px";
            li.style.position = "relative";
        }

        jQuery(li).removeClass("closed").addClass("open");
        
        ul.style.display = "block";
        Jifty.ContextMenu.currently_open = ul.id;
        Jifty.Utils.scrollToShow( ul.id );
    },

    hideOpenMenu: function(event) {
        /* This is a bloody hack to deal with the Document based listener
           firing just before our listener on the link.
           If both fire, the window closes and then opens again.
         */
        if (   Jifty.ContextMenu.prevent_stutter
            && Jifty.ContextMenu.prevent_stutter == Jifty.ContextMenu.currently_open)
        {
            Jifty.ContextMenu.prevent_stutter = "";
            return;
        }
        else {
            Jifty.ContextMenu.prevent_stutter = "";
        }
        
        if (Jifty.ContextMenu.currently_open) {
            Jifty.ContextMenu.hide(Jifty.ContextMenu.currently_open);
        }
    }
};

jQuery(document).click( Jifty.ContextMenu.hideOpenMenu );
Behaviour.register( Jifty.ContextMenu.behaviourRules );

