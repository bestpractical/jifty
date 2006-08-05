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

function buttonToLink(input) {
    var e = $(input);
    if (e) {
        var link = document.createElement("a");
        link.setAttribute("href","#");
        link.setAttribute("onclick",e.getAttribute("onclick"));
        link.setAttribute("name",e.getAttribute("name"));
        link.className = e.className;
        link['virtualform'] = Form.Element.getForm(e);
        link.appendChild(document.createTextNode(e.getAttribute("value")));

        e.parentNode.insertBefore(link, e.nextSibling);
        e.parentNode.removeChild(e);
        return true;
    }
    return false;
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
