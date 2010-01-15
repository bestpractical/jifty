if (typeof Jifty == "undefined") Jifty = { };

(function(){

    /* onPushHandler is called for each new pushed element.
       (currently, this is always a <pushfrag>).  This routine takes
       the pushed element and extracts render mode (Before, After,
       Replace, Delete) , region name and other rendering information.
       Then it calls jifty's "apply_fragment_updates to the item
       inside the <pushfrag> (the actual fragment);

        f is the specification for the new fragment. (region, path,
        mode and other information extracted from the fragment)

       */

    var onPushHandler = function(t) {
        var rid =  t.firstChild.getAttribute('id');
        var f = { region: rid, path: '' };
        f['mode']               =  t.getAttribute('mode');
        f['effect']             =  t.getAttribute('effect');
        f['effect_args']        =  t.getAttribute('effect_args');
        f['remove_effect']      =  t.getAttribute('remove_effect');
        f['remove_effect_args'] =  t.getAttribute('remove_effect_args');

        // If SinglePlugin is enabled, region name will be prefixed
        // "__page-" by the time that region was rendered. Therefore
        // it should also be prefixed the same here.
        if(Jifty.fragments["__page"] != null) {
            f['region'] = "__page-" + f['region']
        }

        f = prepare_element_for_update(f);
        if (f == null) return;
        apply_fragment_updates(t.firstChild, f);
    };

    
    /* This function constructs a new Jifty.Subs object and sets
    up a callback with jQuery.ajax to run our onPushHandler each time
    a new element is added to the hidden iframe's body.

    We could instead say "sets up our transport. every time the
    transport gets a new item, call onPushHandler" */

    /* Jifty.Subs.start() will connect to the iframe transport */

    Jifty.Subs = function(args) {
        var window_id = args.window_id; // XXX: not yet
        var uri = args.uri;
        if (!uri)
            uri = "/=/subs?forever=0";
        
        this.start = function() {
            //push.start();
            var self = this;

            jQuery.ajax({
                url: uri,
                type: "get",
                success: function(responseText) {
                    var container = document.createElement('div');
                    container.innerHTML = responseText;
                    jQuery("pushfrag", container).each(function() {
                        onPushHandler(this);
                    });

                    setTimeout(function() {
                        self.start();
                    }, 1000)
                },
                error: function() {
                }
            });
        }          
    }

})();
