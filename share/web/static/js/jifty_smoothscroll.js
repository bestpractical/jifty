
if (typeof Jifty == "undefined") Jifty = { };

Jifty.SmoothScroll = {
    interval: '',
    steps:    20,

    scrollTo: function( y ) {
        if ( Jifty.SmoothScroll.interval )
            clearInterval( Jifty.SmoothScroll.interval );
        
        var stepsize = parseInt( ( y - Jifty.Utils.getScrollTop() ) / Jifty.SmoothScroll.steps );

        Jifty.SmoothScroll.interval
            = setInterval('Jifty.SmoothScroll.scrollWindow('+stepsize+','+y+')',10);
    },
            
    scrollWindow: function( amount, y ) {
        var curpos  = Jifty.Utils.getScrollTop();
        var isAbove = ( curpos < y );
        
        window.scrollTo( 0, curpos + amount );
        
        var newpos     = Jifty.Utils.getScrollTop();
        var newIsAbove = ( newpos < y );
        
        if ( ( isAbove != newIsAbove ) || ( curpos == newpos ) ) {
            /* We've just scrolled past the destination, or we haven't moved
               from the last scroll (i.e., we're at the bottom of the page),
               so scroll exactly to the position
             */
            window.scrollTo( 0, y );
            clearInterval( Jifty.SmoothScroll.interval );
        }
    }
};
