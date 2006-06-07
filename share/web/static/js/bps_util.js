// XXX TODO This library should likely be refactored to use behaviour

function focusElementById(id) {
    var e = document.getElementById(id);
    if (e) e.focus();
}

function openCalWindow(field) {
    var objWindow = window.open('/helpers/calendar.html?field='+field, 'Calendar', 'height=200,width=235,scrollbars=1');
    objWindow.focus();
}

function updateParentField(field, value) {
    if (window.opener) {
        window.opener.document.getElementById(field).value = value;
        window.close();
    }
}

function createCalendarLink(input) {
    var e = $(input);
    if (e) {
        var link = document.createElement("a");
        link.setAttribute("href", "javascript:openCalWindow('"+e.id+"')");
        
        var img = document.createElement("img");
        img.setAttribute("src", "/static/images/silk/calendar.png");
        img.setAttribute("border", 0);
        link.appendChild(img);
        
        var space = document.createTextNode(" ");
        
        e.parentNode.insertBefore(link, e.nextSibling);
        e.parentNode.insertBefore(space, e.nextSibling);
        
        return true;
    }
    return false;
}

function buttonToLink(input) {
    var e = $(input);
    if (e) {
        var link = document.createElement("a");
        link.setAttribute("href","javascript:$('"+e.id+"').click()");
        link.appendChild(document.createTextNode(e.getAttribute("value")));

        Element.hide(e);
        e.parentNode.insertBefore(link, e.nextSibling);
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
