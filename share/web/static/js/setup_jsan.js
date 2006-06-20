/* Setup JSAN for Jifty defaults */
JSAN.includePath = [ "/static/js/jsan" ];
JSAN.errorLevel  = "none";

/*
 * Stub out JSAN.use to avoid Ajax loading of JSAN libs if they've
 * already been loaded by a <script> tag
 */
JSAN._use = JSAN.use;
JSAN.use  = function() {
    if ( !arguments[0] ) JSAN._use(arguments);
};

