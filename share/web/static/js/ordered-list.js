jQuery(document).ready(function(){
    jQuery("div.ordered-list-container").each(
        function () {
        var box = jQuery(this);
        box.find('ul.unselected').sortable( {
            connectWith: box.find('ul.selected'),
            cancel: 'li.head',
            update: function () {
                if ( jQuery(this).find('li.head').length ) {
                    jQuery(this).find('li.head').prependTo(this);
                }
            }
            });
        box.find('ul.selected').sortable( {
            connectWith: box.find('ul.unselected'),
            cancel: 'li.head',
            update: function () {
                var select = box.find('select.submit');
                select.children('option').remove();
                // make sure head is always the first
                if ( jQuery(this).find('li.head').length ) {
                    jQuery(this).find('li.head').prependTo(this);
                }
                jQuery(this).find('li:not(.head)').each( function() {
                    var value = jQuery(this).find('input.value').val();
                    jQuery('<option selected="selected" value="' + value + '" >' + value + '</option>').appendTo(select);
    });
            }
            });
    });

});
