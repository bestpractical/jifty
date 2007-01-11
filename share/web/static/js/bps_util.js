// XXX TODO This library should likely be refactored to use behaviour

function focusElementById(id) {
    var e = document.getElementById(id);
    if (e) e.focus();
}

function updateParentField(field, value) {
    if (window.opener) {
        window.opener.document.getElementById(field).value = value;
        window.close();
    }
}

function createCalendarLink(id) {
    return Jifty.Calendar.registerDateWidget( id );
}

JSAN.use("DOM.Events");

function buttonToLink(e) {
    var link = document.createElement("a");
    link.setAttribute("href","#");
    link.setAttribute("name",e.getAttribute("name"));

    var form = Form.Element.getForm(e);
    var onclick = e.getAttribute("onclick");

    /* Simple buttons that don't use any JS need us to create an onclick
       for them that makes sure the original button's name gets passed
       and the form submitted normally (without any Ajax-ness)
    */
    if ( !onclick ) {
        DOM.Events.addListener( link, "click", function(ev) {
            var a = ev.target;
            var hidden = document.createElement("input");
            hidden.setAttribute("type", "hidden");
            hidden.setAttribute("name", a.getAttribute("name"));
            a["virtualform"].appendChild( hidden );
            a["virtualform"].submit();
        });
    }
    link.setAttribute("onclick", onclick);

    link.className = e.className;
    link["virtualform"] = form;
    link.appendChild(document.createTextNode(e.getAttribute("value")));

    e.parentNode.insertBefore(link, e.nextSibling);
    e.parentNode.removeChild(e);
    return link;
}

// onload handlers

var onLoadStack     = new Array();
var onLoadLastStack = new Array();
var onLoadExecuted  = 0;

function onLoadHook(commandStr) {
    if(typeof(commandStr) == "string") {
        onLoadStack[onLoadStack.length] = commandStr;
        return true;
    }
    return false;
}

// some things *really* need to be done after everything else
function onLoadLastHook(commandStr) {
    if(typeof(commandStr) == "string"){
        onLoadLastStack[onLoadLastStack.length] = commandStr;
        return true;
    }
    return false;
}

function doOnLoadHooks() {
    if(onLoadExecuted) return;
    for (var x=0; x < onLoadStack.length; x++) { 
        eval(onLoadStack[x]);
    }
    for (var x=0; x < onLoadLastStack.length; x++) { 
        eval(onLoadLastStack[x]); 
    }
    onLoadExecuted = 1;
}


if (typeof window.onload != 'function') {
    window.onload = doOnLoadHooks;
} else {
    var oldonload = window.onload;
    
    window.onload = function() {
        oldonload();
        doOnLoadHooks();
    }
}
