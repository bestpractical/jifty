var hpipe = new Hippie.Pipe();
jQuery(hpipe).bind("message.jifty.fragment", function (e, d) {
    hippie_fragment(d);
});
jQuery(hpipe).bind("message.jifty.result", function (event, d) {
    if (d.error)
        jQuery.jGrowl( d.error, { theme: 'result-error' } );
    else if (d.failure)
        jQuery.each( d.field_errors, function (field, err) {
            jQuery.jGrowl( field+': '+err, { theme: 'result-error' } );
        });
    else
        jQuery.jGrowl( d.message, { theme: 'result-message' } );
});

var hpipe_init = function() {
    var opt = {path: "/__jifty"};
    if (arguments.length)
        opt.client_id = arguments[0];
    hpipe.init(opt);
};
var hippie_fragment = function(f) {
    f = prepare_element_for_update(f);
    if (f == null) return;
    fragment_updates(f, f['args'], f['content']);
};
