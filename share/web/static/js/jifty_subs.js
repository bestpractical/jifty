if (typeof Jifty == "undefined") Jifty = { };

{

    var onPushHandler = function(t) {
	var mode = t.attributes['mode'].nodeValue;
	var rid =  t.firstChild.attributes['id'].nodeValue;
	var f = { region: rid, path: '', mode: mode };
	f = prepare_element_for_update(f);
	apply_fragment_updates(t.firstChild, f);
    };


    Jifty.Subs = function(args) {
	var window_id = args.window_id; // XXX: not yet
	var uri = args.uri;
	if (!uri)
	    uri = "/=/subs?";
	var push = new HTTP.Push({ "uri": uri, interval : 100,
				       "onPush" : onPushHandler});
	
	this.start = function() {
	    push.start();
	};
    }
}
