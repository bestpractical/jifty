// Wikipedia JavaScript toolbar functions

mwEditButtons = [];

// this function generates the actual toolbar buttons with localized text
// we use it to avoid creating the toolbar where javascript is not enabled
function addButton(imageFile, speedTip, tagOpen, tagClose, sampleText) {
	mwEditButtons[mwEditButtons.length] =
		{"imageFile": imageFile,
		 "speedTip": speedTip,
		 "tagOpen": tagOpen,
		 "tagClose": tagClose,
		 "sampleText": sampleText};
}

// this function generates the actual toolbar buttons with localized text
// we use it to avoid creating the toolbar where javascript is not enabled
function mwInsertEditButton(parent, item) {
    if (typeof item.imageFile == 'undefined') {
        return;}
	var image = document.createElement("img");
	image.width = 16;
	image.height = 16;
	image.src = item.imageFile;
	image.border = 0;
	image.alt = item.speedTip;
	image.title = item.speedTip;
	image.style.cursor = "pointer";
	image.onclick = function() {
		insertTags(item.tagOpen, item.tagClose, item.sampleText);
		return false;
	}
	parent.appendChild(image);
}

// apply tagOpen/tagClose to selection in textarea,
// use sampleText instead of selection if there is none
// copied and adapted from phpBB
function insertTags(tagOpen, tagClose, sampleText) {

   // var txtarea = document.getElementsByTagName('TEXTAREA')[0];
    // TODO: need a better way to manage multi textarea
    var txtarea;
    var txtareas = document.getElementsByTagName('TEXTAREA');
    for (i = 0; i < txtareas.length; i++) {
        var textbox = txtareas[i];
        if( textbox.selectionStart ) {
            txtarea = textbox;
        };
    }

    if (typeof txtarea == 'undefined') {
        txtarea = document.getElementsByTagName('TEXTAREA')[0];
    }

	// IE
	if (document.selection && !is_gecko) {
		var theSelection = document.selection.createRange().text;
		if (!theSelection)
			theSelection=sampleText;
		txtarea.focus();
		if (theSelection.charAt(theSelection.length - 1) == " ") { // exclude ending space char, if any
			theSelection = theSelection.substring(0, theSelection.length - 1);
			document.selection.createRange().text = tagOpen + theSelection + tagClose + " ";
		} else {
			document.selection.createRange().text = tagOpen + theSelection + tagClose;
		}

	// Mozilla
	} else if(txtarea.selectionStart || txtarea.selectionStart == '0') {
		var replaced = false;
		var startPos = txtarea.selectionStart;
		var endPos = txtarea.selectionEnd;
		if (endPos-startPos)
			replaced = true;
		var scrollTop = txtarea.scrollTop;
		var myText = (txtarea.value).substring(startPos, endPos);
		if (!myText)
			myText=sampleText;
		if (myText.charAt(myText.length - 1) == " ") { // exclude ending space char, if any
			subst = tagOpen + myText.substring(0, (myText.length - 1)) + tagClose + " ";
		} else {
			subst = tagOpen + myText + tagClose;
		}
		txtarea.value = txtarea.value.substring(0, startPos) + subst +
			txtarea.value.substring(endPos, txtarea.value.length);
		txtarea.focus();
		//set new selection
		if (replaced) {
			var cPos = startPos+(tagOpen.length+myText.length+tagClose.length);
			txtarea.selectionStart = cPos;
			txtarea.selectionEnd = cPos;
		} else {
			txtarea.selectionStart = startPos+tagOpen.length;
			txtarea.selectionEnd = startPos+tagOpen.length+myText.length;
		}
		txtarea.scrollTop = scrollTop;

	// All other browsers get no toolbar.
	// There was previously support for a crippled "help"
	// bar, but that caused more problems than it solved.
	}
	// reposition cursor if possible
	if (txtarea.createTextRange)
		txtarea.caretPos = document.selection.createRange().duplicate();
}



var myrules = {
        '#toolbar' : function(e){
			mwEditButtons = [];
// CUSTOM your toolbar HERE
// addButton : image, help text, first tag before selected text, last tag, default text if nothing is selected
addButton('/static/img/wt/bold.png','Bold text','\*\*','\*\*','Bold text');
addButton('/static/img/wt/italic.png','Italic text','\_','\_','Italic text');
  addButton('/static/img/wt/empty.png','','','','');
addButton('/static/img/wt/h1.png','Title','','\n=======\n','Title');
addButton('/static/img/wt/h2.png','Sub title','','\n-------\n','Sub title');
addButton('/static/img/wt/h3.png','Sub sub title','### ',' ###\n','Sub sub title');
  addButton('/static/img/wt/empty.png','','','','');
addButton('/static/img/wt/link.png','Link','[','](http://...... )','Text');
addButton('/static/img/wt/linkextern.png','URL','<','>','http://.....');
  addButton('/static/img/wt/empty.png','','','','');
addButton('/static/img/wt/ul.png','List','\n- element 1\n- element 2\n- element 3\n\n ','','');
addButton('/static/img/wt/ol.png','Ordered list','\n1. element 1\n1. element 2\n1. element 3\n\n ','','');
// END

	for(i=0;i<mwEditButtons.length;i++) {
		mwInsertEditButton(e, mwEditButtons[i]);
	}

        }
    };
    
Behaviour.register(myrules);

