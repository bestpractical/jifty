/*
   Modified to fix some bugs, use a different css query engine, and to
   to use JSAN classes.
   
   Based on Behaviour v1.1 by Ben Nolan, June 2005, which was based
   largely on the work of Simon Willison.
 
   Usage:   
   
    var myrules = {
        'b.someclass' : function(element){
            element.onclick = function(){
                alert(this.innerHTML);
            }
        },
        '#someid u' : function(element){
            element.onmouseover = function(){
                this.innerHTML = "BLAH!";
            }
        }
    };
    
    Behaviour.register(myrules);
    
    // Call Behaviour.apply() to re-apply the rules (if you
    // update the dom, etc).

*/   

JSAN.use("DOM.Events");
JSAN.use("Upgrade.Array.push");

var Behaviour = {
    searchTimes: {},
    applyTimes: {},
    elements: {},
    list: new Array(),
    
    register: function(sheet) {
        Behaviour.list.push(sheet);
    },
    
    apply: function() {
	var root = arguments[0];
	if(root) root = $(root);
	var _applyStart = new Date();

        for (var h = 0; sheet = Behaviour.list[h]; h++) {
            for (var selector in sheet) {
		var start = new Date();
                var elements = cssQuery(selector, root);
		var searchDone = new Date();
		Behaviour.searchTimes[selector] = searchDone - start;
		Behaviour.elements[selector] = elements;
                
                if ( !elements ) continue;

                for (var i = 0; element = elements[i]; i++) {
                    sheet[selector](element);
		}
		Behaviour.applyTimes[selector] = new Date() - searchDone;
            }
        }
	if(0) {
	    document.write('<h2>Search times:</h2>');
	    document.write('<pre>');
	    for(var k in Behaviour.searchTimes) {
		document.write(Behaviour.searchTimes[k] + '\t' + k + '<br />');
	    }
	    document.write('</pre>');
	    
	    document.write('<h2>Apply times:</h2>');
	    document.write('<pre>');
	    for(var k in Behaviour.applyTimes) {
		document.write(Behaviour.applyTimes[k] + '\t' + k + '<br />');
	    }
	    document.write('</pre>');
	}
	//alert("Applied behaviours in " + (new Date() - _applyStart) + "ms");
    }
}    

DOM.Events.addListener( window, "load", function() { Behaviour.apply() } );
