/**
 * This file overrides functions defined in Interface Elements for jQuery (http://interface.eyecon.ro)
 * so they can work with Jifty. It must be loaded after all Interface scripts, and better before
 * jquery_noconflict.js
 */

jQuery.fn.shake = function() {
    this.each(function(init) {
        var e = jQuery(this);
        e.css('position', 'relative');
        for (var i = 1; i < 5; i++) {
            e.animate({ left: -20/i }, 50)
             .animate({ left: 0 },     50)
             .animate({ left: 20/i },  50)
             .animate({ left: 0 },     50);
        }
    });
    return this;
};

