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


    This Behaviour has been modified to keep track of timing
    information and render it to an on-screen display for profiling
    purposes
*/   

JSAN.use("DOM.Events");
JSAN.use("Upgrade.Array.push");

var Behaviour = {
    profileData: {
	calls: [],
	applyTime: 0,
	searchTime: 0,
	numCalls: 0
    },
    list: new Array(),
    
    register: function(sheet) {
        Behaviour.list.push(sheet);
    },
    
    apply: function() {
	var root = arguments[0];
	if(root) root = $(root);
	var _applyStart = new Date();
	var profile = {
	    searchTimes: {},
	    applyTimes: {},
	    funcs: {},
	    searchTime: 0,
	    applyTime: 0,
	    caller: Behaviour.apply.caller
	};

        for (var h = 0; sheet = Behaviour.list[h]; h++) {
            for (var selector in sheet) {
		var start = new Date();
                var elements = cssQuery(selector, root);
		var searchDone = new Date();
		profile.searchTimes[selector] = searchDone - start;
		profile.searchTime += profile.searchTimes[selector];
                
                if ( !elements ) continue;

                for (var i = 0; element = elements[i]; i++) {
                    sheet[selector](element);
		}
		profile.applyTimes[selector] = new Date() - searchDone;
		profile.applyTime += profile.applyTimes[selector];
		profile.funcs[selector] = sheet[selector];
            }
        }

	Behaviour.profileData.calls.push(profile);
	Behaviour.profileData.numCalls++;
	Behaviour.profileData.searchTime += profile.searchTime;
	Behaviour.profileData.applyTime += profile.applyTime;
    },

    showProfile: function() {
	var pane = this.createElement('div');
	pane.id = 'behaviour-profile-data';

	var title = this.createElement('div');
	title.appendChild(document.createTextNode('Behaviour profiling information'));
	title.className = 'title';
	var close = this.createElement('a', 'close', '[close]');
	close.href = '#';
	close.onclick = function() { Element.remove($('behaviour-profile-data')); }

	pane.appendChild(close);
	pane.appendChild(title);
	
	pane.appendChild(Behaviour._callData());

	document.getElementsByTagName('body')[0].appendChild(pane);

    },

    _callData: function() {
	list = this.createElement('ul', 'section');

	for( var i = 0; i <  Behaviour.profileData.calls.length; i++ ) {
	    var call = Behaviour.profileData.calls[i];
	    var item = this.createElement('li', 'call');
	    var text = call.caller.length == 0 ? ' (Page load)' : ' (AJAX)';
	    var title = this.createElement('div', 'title', 'Call ' + i + text);
	    item.appendChild(title);
	    
	    var table = this.createElement('table');
	    var head = this.createElement('tr');
	    head.appendChild(this.createElement('th', 'selector', 'Selector'));
	    head.appendChild(this.createElement('th', 'time search', 'cssQuery time'));
	    head.appendChild(this.createElement('th', 'time apply', 'Function time'));
	    head.appendChild(this.createElement('th', 'time total', 'Total time'));
	    head.appendChild(this.createElement('th'));
	    table.appendChild(head);

	    var searchTimes = $H(call.searchTimes).keys().sort(function(a,b) {
		    var timeA = call.searchTimes[a] + call.applyTimes[a];
		    var timeB = call.searchTimes[b] + call.applyTimes[b];
		
		    if(timeA < timeB) {
			return 1;
		    } else if(timeA > timeB) {
			return -1;
		    } else {
			return 0;
		    }
		});
	    
	    for(var j = 0; j < searchTimes.length; j++) {
		var k = searchTimes[j];
		var tr = this.createElement('tr');
		tr.appendChild(this.createElement('td', 'selector', k));
		tr.appendChild(this.createElement('td', 'time search', call.searchTimes[k]));
		tr.appendChild(this.createElement('td', 'time apply', call.applyTimes[k]));
		tr.appendChild(this.createElement('td', 'time total', call.searchTimes[k] + call.applyTimes[k]));

		var code  = this.createElement('td', 'code');
		var a = this.createElement('a', null, '[code]');
		a.href = '#';
		var src = this.createElement('code', null, call.funcs[k]);
		var id =  'code-' + i + '-' + j;
		src.id = id;
		src.style.display = 'none';
		// Kludge to make the onclick function close over id properly
		(function (id) {
		    a.onclick = function() { Element.toggle($(id)); return false; }
		})(id);

		var div = this.createElement('div');
		div.appendChild(src);
		code.appendChild(div);
		code.appendChild(a);
		tr.appendChild(code);
		table.appendChild(tr);
	    }

	    item.appendChild(table);

	    item.appendChild(this.createElement('div','totals',
						'Total: '
						+ call.searchTime + ' search, '
						+ call.applyTime + ' apply, '
						+ (call.searchTime + call.applyTime) + ' total'));
					   
	    
	    list.appendChild(item);
	}
	
	return list;
    },


    // Convenience method for the above
    createElement: function (elt, className, text) {
	elt = elt ? elt : 'div';
	var d = document.createElement(elt);
	if(className) d.className = className;
	if(text) d.appendChild(document.createTextNode(text));
	return d;
    },

    onLoad: function () {
	// Make sure we only run once
	if(Behaviour.loaded) return;
	Behaviour.loaded = true;
	Behaviour.apply();

	// Add the profiling CSS to the document
	var head = document.getElementsByTagName('head')[0];
	var link = document.createElement('link');
	link.rel = 'stylesheet';
	link.type = 'text/css';
	link.href = '/css/behaviour-profile.css';
	head.appendChild(link);

	var open = this.createElement('a', null, 'Behaviour profile');
	open.id = 'show-behaviour-profile';
	open.href ='#';
	open.onclick = function() { Behaviour.toggleProfile() }
	var div = this.createElement('div');
	div.appendChild(open);
	document.getElementsByTagName('body')[0].appendChild(div);
    },

    toggleProfile: function () {
	var e = $('behaviour-profile-data');
	if(e) {
	    Element.remove(e);
	} else {
	    this.showProfile();
	}
    }
}


DOM.Events.addListener( window, "load", function() { Behaviour.onLoad() } );
