jQuery(document).ready(function(){
    jQuery("div.ordered-list-container ul.unselected").sortable({
        connectWith: 'ul.selected',
        cancel: 'li.head'
    });

    jQuery("div.ordered-list-container ul.selected").sortable({
        connectWith: 'ul.unselected',
        cancel: 'li.head',
        update: function () {
            var box = jQuery(this).parents('div.ordered-list-container');
            var select = box.find('select.submit');
            select.children('option').remove();
            jQuery(this).find('li:not(.head)').each( function() {
                var value = jQuery(this).find('input.value').val();
                jQuery('<option selected="selected" value="' + value + '" >' + value + '</option>').appendTo(select);
    });
        }
    });
});
