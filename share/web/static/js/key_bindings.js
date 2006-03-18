// Copyright 2004-2005, Best Practical Solutions, LLC
// This Library is licensed to you under the same terms as Perl 5.x

var bindings = Array;

document.onkeydown = doClick;
function doClick(e) {
    var targ;
        if (!e) var e = window.event;
            if (e.target) targ = e.target;
            else if (e.srcElement) targ = e.srcElement;
        if (targ.nodeType == 3) // defeat Safari bug
                targ = targ.parentNode;
   
   // safari or mozilla
   if ( ( ! e.metaKey && ! e.altKey &&  ! e.ctrlKey )
        && (
        (targ == document.body) || 
       (targ ==  document.getElementsByTagName('html')[0])  
        ) ){
	var code = String.fromCharCode(e.keyCode);
    var binding = getKeyBinding(code);
   if (binding) {
   if (binding["action"] == "goto") {
        document.location = (binding["data"]);
    } 
   else if (binding["action"] == "focus") {
      var elements = document.getElementsByName(binding["data"]);
       elements[0].focus();
    }
   else if (binding["action"] == "click") {
      var elements = document.getElementsByName(binding["data"]);
       elements[0].click();
    }

 }     

}
}

function addKeyBinding(key, action, data, label) {
    var binding = new Array;
    binding["action"] = action;
    binding["data"] = data;
    binding["label"] = label;
    bindings[key] = binding;
}


function getKeyBinding(key) {
    return(bindings[key]);
}


function writeKeyBindingLegend() {
    var content = '';
    for  (var key in bindings) {
    if ( bindings[key]['label']) {
    content = content + '<div class="keybinding"><dt>'+key + '</dt>' +'<dd>'+bindings[key]['label'] +'</dd></div>'; 
    }
    }
    if (content) {
    document.write('<div class="keybindings">');
    document.write('<dl class="keybindings">');
    document.write(content);
    document.write('</dl>');
    document.write('</div>');
    }
}
