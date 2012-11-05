var pubsub = new Hippie.Pipe();
jQuery(pubsub).bind("message.jifty.fragment", function (event, d) {
    d = prepare_element_for_update(d);
    if (d == null) return;
    fragment_updates(d, d['args'], d['content']);
});
jQuery(pubsub).bind("message.jifty.result", function (event, d) {
    if (d.error)
        jQuery.jGrowl( d.error, { theme: 'result-error' } );
    else if (d.failure)
        jQuery.each( d.field_errors, function (field, err) {
            jQuery.jGrowl( field+': '+err, { theme: 'result-error' } );
        });
    else
        jQuery.jGrowl( d.message, { theme: 'result-message' } );
});

var pubsub_init = function() {
    var opt = {path: "/__jifty"};
    if (arguments.length)
        opt.client_id = arguments[0];
    pubsub.init(opt);
};
