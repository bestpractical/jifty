var hpipe = new Hippie.Pipe();
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
    hpipe.init({path: "/__jifty"});
};
