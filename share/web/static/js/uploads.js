jQuery(document).ready(function(){
    jQuery('div.uploads .attach-more').click(
        function () {
            var box = jQuery(this).closest('div.uploads');
            var name = box.find('input[type=file]:first').attr('name');
            var cla = box.find('input[type=file]:first').attr('class');
            jQuery('<input type="file" name=' + name + '" class="' + cla + '" />').insertBefore(this);

            // actually, firefox doesn't really support "click" here
            box.find('input[type=file]:last').click();
            return false;
        } );
});

