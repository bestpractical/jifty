// Compatible notice for old school

(function($) {
    $.each(
        Jifty.Form,
        function(k, v) {
            if ( $.isFunction(v) && Form[k] == null ) {
                Form[k] = function() {
                    alert("Form." + k +
                          " is going to be depcreated. Please use Jifty.Form." + k +
                          " instead.");
                    v.apply(Jifty.Form, arguments);
                }
            }
        }
    );

    $.each(
        Jifty.Form.Element,
        function(k, v) {
            if ( $.isFunction(v) && Form.Element[k] == null ) {
                Form.Element[k] = function() {
                    alert("Form.Element" + k +
                          " is going to be depcreated. Please use Jifty.Form.Element" + k +
                          " instead.");
                    v.apply(Jifty.Form.Element, arguments);
                }
            }
        }
    );

})(jQuery);

