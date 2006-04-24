// Copyright 2004-2006, Best Practical Solutions, LLC
// This Library is licensed to you under the same terms as Perl 5.x

JSAN.use("DOM.Events");

if ( typeof Jifty == "undefined" ) Jifty = {};

Jifty.KeyBindings = {
    bindings: new Array(),
    listener: null,

    activate: function() {
        if ( Jifty.KeyBindings.listener )
            return;
        
        Jifty.KeyBindings.listener = DOM.Events.addListener(
                                        window,
                                        "keydown",
                                        Jifty.KeyBindings.doClick
                                     );
    },

    deactivate: function() {
        DOM.Events.removeListener(Jifty.KeyBindings.listener);
    },

    doClick: function(e) {
        if (e.target.nodeType == 3) // defeat Safari bug
            e.target = e.target.parentNode;
       
        // Safari or Mozilla
        if (    ( !e.metaKey && !e.altKey && !e.ctrlKey )
             && (    (e.target == document.body)
                  || (e.target == document.getElementsByTagName("html")[0]) ))
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
             || Element.hasClassName(e, 'keybindings-written') )
            return;
        
        
        /* definition list */
        var dl = document.createElement("dl");
        dl.setAttribute("class", "keybindings");

    
        /* terms of the list */
        
        for (var key in Jifty.KeyBindings.bindings) {
            if ( Jifty.KeyBindings.get(key)["label"] ) {
                var div = document.createElement("div");
                div.setAttribute("class", "keybinding");
                
                var dt = document.createElement("dt");
                dt.appendChild( document.createTextNode( key ) );

                var dd = document.createElement("dd");
                dd.appendChild( document.createTextNode( Jifty.KeyBindings.get(key)["label"] ) );
                
                div.appendChild( dt );
                div.appendChild( dd );
                dl.appendChild( div );
            }
        }
        
        e.appendChild( dl );
        Element.addClassName(e, 'keybindings-written');
        
        /* since we wrote the legend, now obey it */
        Jifty.KeyBindings.activate();
    }
}

Behaviour.register({ "div.keybindings": Jifty.KeyBindings.writeLegend });

