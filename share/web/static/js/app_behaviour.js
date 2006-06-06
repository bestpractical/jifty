/*
 * Doc below taken from http://ripcord.co.nz/behaviour/
 *
IMPORTANT: if you make DOM changes that mean that an element
ought to gain or lose a behaviour, call Behaviour.apply()!

(Actually, that *won't* make something lose a behaviour, so if that's necessary
you'll need to have an empty "fallback".  I.E. If "div#foo a" should have a
special onclick and other "a" shouldn't, then there ought to be an explicit "a"
style that sets onclick to a trivial function, if DOM changes will ever happen.)
(Also, with the current behaviour.js, the order of application of styles is
undefined, so you can't really do cascading.  I've suggested to the author
that he change it; if he doesn't, but we need it, it's an easy change to make
the sheets arrays instead of Objects (hashes).  For now this can be dealt with
by loading multiple sheets (register calls), though.)
*/

/* Here's an example... */


/*
var myrules = {
    "h2.rounded": function(element) {
        Rico.Corner.round(element);
    }
};
        
Behaviour.register(myrules);
*/
