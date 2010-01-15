// Copyright 2004-2010, Best Practical Solutions, LLC
// This Library is licensed to you under the same terms as Perl 5.x

if ( typeof Jifty == "undefined" ) Jifty = {};

Jifty.KeyBindings = {
    bindings: new Array(),
    listener: false,

    activate: function() {
        if ( Jifty.KeyBindings.listener )
            return;
        
        jQuery(document).keydown( Jifty.KeyBindings.doClick );
        Jifty.KeyBindings.listener = true;
    },

    deactivate: function() {
        jQuery(document).unbind( "keydown", Jifty.KeyBindings.doClick );
        Jifty.KeyBindings.listener = false;
    },

    reset: function() {
        Jifty.KeyBindings.bindings = new Array();
    },

    doClick: function(e) {
        if (e.target.nodeType == 3) // defeat Safari bug
            e.target = e.target.parentNode;
       
        /* XXX TODO: Is there a better way to do this and still support
                     opera?
         */            
        if (    !e.metaKey && !e.altKey && !e.ctrlKey
             && !e.target.nodeName.match(/^(INPUT|TEXTAREA)$/) )
        {
            var code    = String.fromCharCode(e.keyCode);
            var binding = Jifty.KeyBindings.get(code);
            
            if (binding) {
                e.preventDefault();
                
                if (binding["action"] == "goto") {
                    document.location = (binding["data"]);
                }
                else if (binding["action"] == "focus") {
                    var elements = document.getElementsByName(binding["data"]);
                    elements[0].focus();
                }
                else if (binding["action"] == "click") {
                    var elements = document.getElementsByName(binding["data"]);
                    elements[0].click();
                }
            }
        }
    },

    add: function(key, action, data, label) {
        var binding = new Array();
        binding["action"]  = action;
        binding["data"]    = data;
        binding["label"]   = label;
        Jifty.KeyBindings.bindings[key] = binding;
    },

    get: function(key) {
        return Jifty.KeyBindings.bindings[key];
    },

    writeLegend: function(e) {
        if (    !document.createElement
             || !document.createTextNode
                || jQuery(e).is('.keybindings-written') )
            return;
        
        
        /* definition list */
        var dl = document.createElement("dl");
        dl.className = "keybindings";

    
        /* terms of the list */
        
        for (var key in Jifty.KeyBindings.bindings) {
            if ( Jifty.KeyBindings.get(key)["label"] ) {
                var div = document.createElement("div");
                div.className = "keybinding";
                
                var dt = document.createElement("dt");
                dt.appendChild( document.createTextNode( key ) );

                var dd = document.createElement("dd");
                dd.appendChild( document.createTextNode( Jifty.KeyBindings.get(key)["label"] ) );
                
                div.appendChild( dt );
                div.appendChild( dd );
                dl.appendChild( div );
            }
        }
        
        if ( dl.hasChildNodes() ) {
            var label = document.createElement("div");
            label.className = "keybindings_label";
            label.appendChild( document.createTextNode("Hotkeys:") );
            
            e.appendChild( label );
            e.appendChild( dl );
            jQuery(e).addClass('keybindings-written');
        
            /* since we wrote the legend, now obey it */
            Jifty.KeyBindings.activate();
        }
    }
}

Behaviour.register({ "#keybindings": Jifty.KeyBindings.writeLegend });
