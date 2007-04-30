
// WYZZ Copyright (c) 2007 The Mouse Whisperer
// Contains code Copyright (c) 2006 openWebWare.com
// This copyright notice MUST stay intact for use.
//
// An open source WYSIWYG editor for use in web based applications.
// For full source code and docs, visit http://www.wyzz.info
//
// This library is free software; you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation; either version 2.1 of the License, or 
// (at your option) any later version.
//
// This library is distributed in the hope that it will be useful, but 
// WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
// or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public 
// License for more details.
//
// You should have received a copy of the GNU Lesser General Public License along 
// with this library; if not, write to the Free Software Foundation, Inc., 59 
// Temple Place, Suite 330, Boston, MA 02111-1307 USA 
/****************************************************************************************/
// MODIFY THE PARAMETERS IN THE FOLLOWING SECTION TO SUIT YOUR APPLICATION ///////////////

// Editor Width and Height
wyzzW = 600;
wyzzH = 200;

// Number of toolbars - must be either 1 or 2
// If set to 1, the first tooolbar (defined in array buttonName below) will be ignored
toolbarCount = 2;

// Edit region stylesheet
editstyle = '/static/wyzzstyles/editarea.css';

// Do we want to try to clean the code to emulate xhtml? 1=Yes, 0=No
xhtml_out = 1;

// Style Sheet
document.write('<link rel="stylesheet" type="text/css" href="/static/wyzzstyles/style.css">\n');

// TOOLBARS ARRAYS
// Order of available commands in toolbar
// Remove from this any buttons not required in your application
var buttonName = new Array("font","headers","separator","bold","italic","underline","strikethrough","separator","cut","copy","paste","separator","subscript","superscript","separator","justifyleft","justifycenter","justifyright","justifyfull","indent","outdent","separator","insertunorderedlist","insertorderedlist","separator","link","insertimage","separator","undo","redo");

// Order of available commands in toolbar2
// Remove from this any buttons not required in your application
var buttonName2 = new Array("specialchar","separator","forecolor","backcolor","separator","inserthorizontalrule","separator","removeformat","separator","upsize","downsize","separator","htmlmode","separator","help");

var myFonts = new Array("Andale Mono","Georgia","Verdana","Arial","Arial Black","impact","Times New Roman","Courier New","Comic Sans MS","Helvetica","Trebuchet MS","Tahoma");

var specialChars = new Array("&copy;","&reg;","&#153;","&agrave;","&aacute;","&ccedil;","&egrave;","&eacute;","&euml;","&igrave;","&iacute;","&ntilde;","&ograve;","&oacute;","&ouml;","&ugrave;","&uacute;","&uuml;","&pound;","&cent;","&yen;","&euro;","&#147;","&#148;","&laquo;","&raquo;","&#149;","&#151;","&#133;","&para;","&#8224;","&#8225;","&times;","&divide;","&deg;","&plusmn;","&frac14;","&frac12;","&frac34;","&not;","&lt;","&gt;","&Delta;","&lambda;","&Phi;","&Psi;","&Sigma;","&int;","&alpha;","&beta;","&Omega;","&mu;","&pi;","&theta;","&harr;","&infin;","&radic;","&asymp;","&ne;","&equiv;","&le;","&ge;","&iexcl;","&iquest;","&spades;","&clubs;","&hearts;","&diams;");

// DON'T MODIFY BEYOND THIS LINE unless you know what you are doing //////////////
/********************************************************************************/

version = "0.62"; // Please leave this

var Headers = new Array("P","PRE","H1","H2","H3","H4","H5","H6");

// Mode wysiwyg = 1 or sourcecode = 0
mode = 1;

// Get browser
browserName = navigator.appName;

nlBefore = new Array("div","p","li","h1","h2","h3","h4","h5","h6","hr","ul","ol");

function h2x(node,inPre) { // we will pass the node containing the Wyzz-generated html
  var xout = '';
  var i;
  var j;
  // for each child of the node
  for(i=0;i<node.childNodes.length;i++) {
  if(node.childNodes[i].parentNode && String(node.tagName).toLowerCase() != String(node.childNodes[i].parentNode.tagName).toLowerCase()) continue;
  // alert('Nodes: '+ node.childNodes.length);
  switch(node.childNodes[i].nodeType) {
    case 1: { // for element nodes
      // get tag name
      var tagname = String(node.childNodes[i].tagName).toLowerCase();
      if(tagname == '') break;
      if((indexOf(nlBefore,tagname)!=-1)&&(!inPre)) { // this tag needs line break before it
        xout += '\n';
      }
      xout += '<' + tagname;
      var atts = node.childNodes[i].attributes;
      var attvalue;
      for(j=0;j<atts.length;j++) { // for each attribute
        var attname = atts[j].nodeName.toLowerCase();
        if(!atts[j].specified) continue;
        var validatt = true;
        switch(attname) {
          case "style": attvalue = node.childNodes[i].style.cssText; break;
          case "class": attvalue = node.childNodes[i].className; break;
          case "name": attvalue = node.childNodes[i].name; break;
          default:
            try {
              attvalue = node.childNodes[i].getAttribute(attname,2);
            } catch(e) {
              validatt = false;
            }
          }
          if(validatt) {
            if(!(tagname=='li' && attname == 'value')) {
              xout += ' '+attname + '="' + fixatt(attvalue) + '"';
            }
          }
        }
        if(tagname == 'img' && attname == 'alt') {
          xout += ' alt=""';
        }
        if(node.childNodes[i].canHaveChildren||node.childNodes[i].hasChildNodes()) {
          xout += '>';
          xout += h2x(node.childNodes[i],tagname=='pre'?true:false);
          xout += '</' + tagname + '>';
        } else {
          if(tagname == 'style'||tagname == 'title'||tagname=='script'||tagname=='textarea'||tagname=='a') {
            xout += '>';
            var innertext;
            if(tagname=='script') {
              innertext = node.childNodes[i].text;
            } else {
              innertext = node.childNodes[i].innerHTML;
            }
            if(tagname=='style') {
              innertext = String(innertext).replace(/[\n]+/g,'\n');
            }
            xout += innertext + '</' + tagname + '>';
          } else {
            xout += '/>';
          }
        }
      break;
    }
//    else if(node.childNodes[i].nodeType == 2) { // for attribute nodes
    
//    }
    case 3: { // for text nodes
      if(!inPre) { // don't change inside a <pre> tag
        if(node.childNodes[i] != '\n') {
          xout += fixents(fixtext(node.childNodes[i].nodeValue));
        }
      } else {
          xout += node.childNodes[i].nodeValue;     
        break;
      }
    }
    default: 
      break;
    }
  }
  return xout;
}

function fixents(text) {
  var i;
  var ents = {8364 : "euro",402  : "fnof",8240 : "permil",352  : "Scaron",338  : "OElig",381  : "#381",8482 : "trade",353  : "scaron",339  : "oelig",382  : "#382",376  : "Yuml",162  : "cent",163  : "pound",164  : "curren",165  : "yen",166  : "brvbar",167  : "sect",168  : "uml",169  : "copy",170  : "ordf",171  : "laquo",172  : "not",173  : "shy",174  : "reg",175  : "macr",176  : "deg",177  : "plusmn",178  : "sup2",179  : "sup3",180  : "acute",181  : "micro",182  : "para",183  : "middot",184  : "cedil",185  : "sup1",186  : "ordm",187  : "raquo",188  : "frac14",189  : "frac12",190  : "frac34",191  : "iquest",192  : "Agrave",193  : "Aacute",194  : "Acirc",195  : "Atilde",196  : "Auml",197  : "Aring",198  : "AElig",199  : "Ccedil",200  : "Egrave",201  : "Eacute",202  : "Ecirc",203  : "Euml",204  : "Igrave",205  : "Iacute",206  : "Icirc",207  : "Iuml",208  : "ETH",209  : "Ntilde",210  : "Ograve",211  : "Oacute",212  : "Ocirc",213  : "Otilde",214  : "Ouml",215  : "times",216  : "Oslash",217  : "Ugrave",218  : "Uacute",219  : "Ucirc",220  : "Uuml",221  : "Yacute",222  : "THORN",223  : "szlig",224  : "agrave",225  : "aacute",226  : "acirc",227  : "atilde",228  : "auml",229  : "aring",230  : "aelig",231  : "ccedil",232  : "egrave",233  : "eacute",234  : "ecirc",235  : "euml",236  : "igrave",237  : "iacute",238  : "icirc",239  : "iuml",240  : "eth",241  : "ntilde",242  : "ograve",243  : "oacute",244  : "ocirc",245  : "otilde",246  : "ouml",247  : "divide",248  : "oslash",249  : "ugrave",250  : "uacute",251  : "ucirc",252  : "uuml",253  : "yacute",254  : "thorn",255  : "yuml",913  : "Alpha",914  : "Beta",915  : "Gamma",916  : "Delta",917  : "Epsilon",918  : "Zeta",919  : "Eta",920  : "Theta",921  : "Iota",922  : "Kappa",923  : "Lambda",924  : "Mu",925  : "Nu",926  : "Xi",927  : "Omicron",928  : "Pi",929  : "Rho",	931  : "Sigma",932  : "Tau",933  : "Upsilon",934  : "Phi",935  : "Chi",936  : "Psi",937  : "Omega",8756 : "there4",8869 : "perp",945  : "alpha",946  : "beta",947  : "gamma",948  : "delta",949  : "epsilon",950  : "zeta",951  : "eta",952  : "theta",953  : "iota",954  : "kappa",955  : "lambda",956  : "mu",957  : "nu",968  : "xi",969  : "omicron",960  : "pi",961  : "rho",962  : "sigmaf",963  : "sigma",964  : "tau",965  : "upsilon",966  : "phi",967  : "chi",968  : "psi",969  : "omega",8254 : "oline",8804 : "le",8260 : "frasl",8734 : "infin",8747 : "int",9827 : "clubs",9830 : "diams",9829 : "hearts",9824 : "spades",8596 : "harr",8592 : "larr",8594 : "rarr",8593 : "uarr",8595 : "darr",8220 : "ldquo",8221 : "rdquo",8222 : "bdquo",8805 : "ge",8733 : "prop",8706 : "part",8226 : "bull",8800 : "ne",8801 : "equiv",8776 : "asymp",8230 : "hellip",8212 : "mdash",8745 : "cap",8746 : "cup",8835 : "sup",8839 : "supe",8834 : "sub",8838 : "sube",8712 : "isin",8715 : "ni",8736 : "ang",8711 : "nabla",8719 : "prod",8730 : "radic",8743 : "and",8744 : "or",8660 : "hArr",8658 : "rArr",9674 : "loz",8721 : "sum",8704 : "forall",8707 : "exist",8216 : "lsquo",8217 : "rsquo",161  : "iexcl",977  : "thetasym",978  : "upsih",982  : "piv",8242 : "prime",8243 : "Prime",8472 : "weierp",8465 : "image",8476 : "real",8501 : "alefsym",8629 : "crarr",8656 : "lArr",8657 : "uArr",8659 : "dArr",8709 : "empty",8713 : "notin",8727 : "lowast",8764 : "sim",8773 : "cong",8836 : "nsub",8853 : "oplus",8855 : "otimes",8901 : "sdot",8968 : "lceil",8969 : "rceil",8970 : "lfloor",8971 : "rfloor",9001 : "lang",9002 : "rang",710  : "circ",732  : "tilde",8194 : "ensp",8195 : "emsp",8201 : "thinsp",8204 : "zwnj",8205 : "zwj",8206 : "lrm",8207 : "rlm",8211 : "ndash",8218 : "sbquo",8224 : "dagger",8225 : "Dagger",8249 : "lsaquo",8250 : "rsaquo"};

  var new_text = '';

  var temp = new RegExp();
  temp.compile("[a]|[^a]", "g");

  var parts = text.match(temp);

  if (!parts) return text;
  for (i=0; i<parts.length; i++) {
    var c_code = parseInt(parts[i].charCodeAt());
    if (ents[c_code]) {
      new_text += "&"+ents[c_code]+";";
    } else new_text += parts[i];
  }
  return new_text;
}

function fixtext(text) {
  var temptext = String(text).replace(/\&lt;/g,"#h2x_lt").replace(/\&gt;/g,"#h2x_gt");
  temptext = temptext.replace(/\n{2,}/g,"\n").replace(/\&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/\u00A0/g,"&nbsp;");
  return temptext.replace(/#h2x_lt/g,"&alt;").replace(/#h2x_gt/g,"&gt;");
}

function fixatt(text) {
  var temptext = String(text).replace(/\&lt;/g,"#h2x_lt").replace(/\&gt;/g,"#h2x_gt");
  temptext = temptext.replace(/\&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/\"/g,"&quot;");
  return temptext.replace(/#h2x_lt/g,"&alt;").replace(/#h2x_gt/g,"&gt;");  
}

function indexOf(thisarray, value)
{
    var i;
    for (i=0; i < thisarray.length; i++) {
        if (thisarray[i] == value) {
            return i;
        }
    }
    return -1;
}

// Color picker - here we make an array of all websafe colors
// If you want to limit the colors available to users (e.g. to fit in with
// a site design) then use a restricted array of colors
// e.g. var buttonName = new Array("336699","66abff", .... etc
var buttonColors = new Array(216);

// Colors - replace this function with your own if you have special requirements for colors
function getColorArray() {
// Color code table 
c = new Array('00', '33', '66', '99', 'cc', 'ff'); 
var count = 0;
// Iterate red
for (r = 0; r < 6; r++) 
  { 
    // Iterate green
    for (g = 0; g < 6; g++) 
      { 
        // Iterate blue
        for (b = 0; b < 6; b++) 
          { 
            // Get RGB color
            buttonColors[count] = c[r] + c[g] + c[b]; 
            count++;
          } 
      } 
  }
}

getColorArray();
	
/* Emulates insertAdjacentHTML(), insertAdjacentText() and insertAdjacentElement() three functions 
so they work with Netscape 6/Mozilla - By Thor Larholm me@jscript.dk */
if(typeof HTMLElement!="undefined" && !HTMLElement.prototype.insertAdjacentElement) {
  HTMLElement.prototype.insertAdjacentElement = function (where,parsedNode) {
  switch (where) {
    case 'beforeBegin':
      this.parentNode.insertBefore(parsedNode,this)
      break;
    case 'afterBegin':
      this.insertBefore(parsedNode,this.firstChild);
      break;
    case 'beforeEnd':
      this.appendChild(parsedNode);
      break;
    case 'afterEnd':
      if (this.nextSibling) {
        this.parentNode.insertBefore(parsedNode,this.nextSibling);
      } else {
        this.parentNode.appendChild(parsedNode);
        break;
      }
    }
  }

  HTMLElement.prototype.insertAdjacentHTML = function (where,htmlStr) {
    var r = this.ownerDocument.createRange();
    r.setStartBefore(this);
    var parsedHTML = r.createContextualFragment(htmlStr);
    this.insertAdjacentElement(where,parsedHTML)
  }

  HTMLElement.prototype.insertAdjacentText = function (where,txtStr) {
    var parsedText = document.createTextNode(txtStr)
    this.insertAdjacentElement(where,parsedText)
  }
}

function closeColorPicker(thisid) {
  document.getElementById(thisid).style.display = "none";
}

// the hyperlink dialog
function insertLink(n) {
  var newWindow = '';
  var linkurl = '';
  var linktitle = '';
  var targetText = grabSelectedText(n);
  var linkurl = prompt('Enter the target URL of the link:');
  var linktitle = prompt('Please give a title for the link:');
  var openNew = confirm('Should this link open in a new window?\n\nOK = Open in NEW Window\nCancel = Open in THIS window');
  if(openNew)     {
    newWindow = "blank";
  } else {
    newWindow = "self";
  }    
  if(newWindow==''||linkurl==''||linktitle=='') {
    alert('Please enter all the required information.');
    insertLink(n);
  } else {
    var hyperLink = '<a href="' + linkurl + '" target="_' + newWindow + '" title="' + linktitle + '">' + targetText + '</a>';
    insertHTML(hyperLink, n);
  }
}
  
function insertImage(n) {
  var imgurl = prompt('Enter the target URL of the image:');
  var imgtitle = prompt('Please give a title for the link:');
  var theImage = '<img src="' + imgurl + '" title="' + imgtitle + '" />';
  insertHTML(theImage, n);  }

function make_wyzz(textareaID) {
  
  // Hide the textarea 
  document.getElementById(textareaID).style.display = 'none'; 
	
  // get textareaID
  var n = textareaID;
	
  // Toolbars width is 2 pixels wider than the editor
  toolbarWidth = parseFloat(wyzzW) + 2;

  var toolbar = '';
  
  // We only generate toolbar 1 if toolbarCount is set to 2
  if(toolbarCount == 2) {
    // Generate WYSIWYG toolbar
    toolbar =  '<table cellpadding="0" cellspacing="0" border="0" class="toolbar" style="width:' + toolbarWidth + 'px;"><tr>';
  
    // Output buttons for toolbar
    var colNumbers = 0;
    for (btn in buttonName) {
     if ( colNumbers < buttonName.length ) {
      colNumbers ++;
      if(buttonName[btn] == "separator") {
        toolbar += '<td class="separator">&nbsp;</td>';
        } else {
        toolbar += '<td style="width: 22px;"><img src="/static/img/wyzzicons/' +buttonName[btn]+ '.gif" border=0 unselectable="on" title="' +buttonName[btn]+ '" id="' +buttonName[btn]+ '" class="cmdbutton" onClick="formatText(this.id,\'' + n + '\');" onmouseover="if(className==\'cmdbutton\'){className=\'buttonOver\'};" onmouseout="if(className==\'buttonOver\'){className=\'cmdbutton\'};" unselectable="on" width="20" height="20"></td>';
        }
     }
	}
    toolbar += '<td>&nbsp;</td></tr></table>';
  }
  
  
  // Generate WYSIWYG toolbar2
  var toolbar2 =  '<table cellpadding="0" cellspacing="0" border="0" class="toolbar" style="width:' + toolbarWidth + 'px;"><tr>';
  
  // Output buttons for toolbar2
  var colNumbers = 0;
  for (btn in buttonName2) {
   if ( colNumbers < buttonName2.length ) {
    colNumbers ++;
    if(buttonName2[btn] == "separator") {
      toolbar2 += '<td class="separator">&nbsp;</td>';
      } else {
      toolbar2 += '<td style="width: 22px;"><img src="/static/img/wyzzicons/' +buttonName2[btn]+ '.gif" border=0 unselectable="on" title="' +buttonName2[btn]+ '" id="' +buttonName2[btn]+ '" class="cmdbutton" onClick="formatText(this.id,\'' + n + '\');" onmouseover="if(className==\'cmdbutton\'){className=\'buttonOver\'};" onmouseout="if(className==\'buttonOver\'){className=\'cmdbutton\'};" unselectable="on" width="20" height="20"></td>';
       }
	  }
  }
  toolbar2 += '<td>&nbsp;</td></tr>';

// the foreground color picker
  var swatchcount = 0;
  toolbar2 += '<tr><td colspan=' + colNumbers + '>';
  toolbar2 += '<div id="colorpicker' + n + '" class="colorpicker" style="display:none">';
    for (clr in buttonColors) {
      toolbar2 += '<a href="#" title="#' + buttonColors[clr] + '" alt="#' + buttonColors[clr] + '" "class="colorButton" onClick="formatTextColor(\'' + buttonColors[clr] + '\',\'' + n + '\');" style="background: #' + buttonColors[clr] + '">&nbsp;</a>';
      swatchcount++;
      if(swatchcount%18==0) {
        toolbar2 += '<br>';
      }
    }
    toolbar2 += '<img class="closebutton" src="/static/img/wyzzicons/close.gif" border=0 onclick="closeColorPicker(\'colorpicker' + n + '\')"></div>';
  // the background color picker
  toolbar2 += '<div id="colorbackpicker' + n + '" class="colorpicker" style="display:none">';
  for (clr in buttonColors) {
    toolbar2 += '<a href="#" title="#' + buttonColors[clr] + '" alt="#' + buttonColors[clr] + '" class="colorButton" onClick="formatBackColor(\'' + buttonColors[clr] + '\',\'' + n + '\');" style="background: #' + buttonColors[clr] + '">&nbsp;</a>';
    swatchcount++;
    if(swatchcount%18==0) {
      toolbar2 += '<br>';
    }
  }
  toolbar2 += '<img class="closebutton" src="/static/img/wyzzicons/close.gif" border=0 onclick="closeColorPicker(\'colorbackpicker' + n + '\')"></div>'; 
  // the font picker
  toolbar2 += '<div id="fontpicker' + n + '" class="fontpicker" style="display:none">';
  var fCount = 0;
  for (fnt in myFonts) {
   if (fCount < myFonts.length) {
    fCount ++ ;
    toolbar2 += '<a href="#" class="fontSelect" onClick="formatFontName(\'' + myFonts[fnt] + '\',\'' + n + '\');" style="font-size:14px;padding: 0px 0px 0px 30px;font-family:' + myFonts[fnt] +'">' + myFonts[fnt] +'</a>';
    toolbar2 += '<br>';
   }
  }
  toolbar2 += '<img class="closebutton" src="/static/img/wyzzicons/close.gif" border=0 onclick="closeColorPicker(\'fontpicker' + n + '\')"></div>'; 
  // the special character picker
  toolbar2 += '<div id="specialpicker' + n + '" class="specialpicker" style="display:none"><table><tr>';
  var charcount = 0;
  for (chr in specialChars) {
   if ( charcount < specialChars.length ) {
    toolbar2 += '<td><a href="#" onClick="formatSpecialChar(\'' + specialChars[chr] + '\',\'' + n + '\');">' + specialChars[chr] + '</a>&nbsp;</td>';
    charcount++;
    if(charcount%10==0) {
      toolbar2 += '</tr><tr>';
    }
   }
  }
  toolbar2 += '</tr></table><br><img class="closebutton" src="/static/img/wyzzicons/close.gif" border=0 onclick="closeColorPicker(\'specialpicker' + n + '\')"></div>'; 
  // the header picker
  toolbar2 += '<div id="headerpicker' + n + '" class="headerpicker" style="display:none">';
  var hdrcount = 0;
  for (hdr in Headers) {
   if ( hdrcount < Headers.length ) {
   hdrcount ++;
    toolbar2 += '<a href="#" class="headerSelect" onClick="formatHeader(\'' + Headers[hdr] + '\',\'' + n + '\');" style="font-size:14px;padding: 0px 0px 0px 30px;font-family:arial">' + Headers[hdr] +'</a>';
    toolbar2 += '<br>';
   }
  }
  toolbar2 += '<img class="closebutton" src="/static/img/wyzzicons/close.gif" border=0 onclick="closeColorPicker(\'headerpicker' + n + '\')"></div>'; 
  // Add extra popups here
  // The help/about box
  // The copyright and link must remain unaltered
  toolbar2 += '<div id="helpbox' + n + '" class="helpbox" style="display:none">';
  toolbar2 += '<div class="help"><h4><img src="/static/img/wyzzicons/wyzzicon.gif" align="middle">Wyzz v' + version + '</h4><br>&copy; 2007 <a href="http://www.wyzz.info" target=_blank>www.wyzz.info</a><br><br></div>';
  toolbar2 += '<img class="closebutton" src="/static/img/wyzzicons/close.gif" border=0 onclick="closeColorPicker(\'helpbox' + n + '\')"></div></td></tr></table>';   

// Create iframe for editor
var iframe = '<table cellpadding="0" cellspacing="0" border="0" style="width:' + wyzzW + 'px; height:' + wyzzH + 'px;border: 1px inset #dddddd;"><tr><td valign="top">\n'
  + '<iframe frameborder="0" id="wysiwyg' + n + '"></iframe>\n'
  + '</td></tr></table>\n';
  
  // Insert toolbar after the textArea
  document.getElementById(n).insertAdjacentHTML("afterEnd", toolbar + toolbar2 + iframe);
	
  // Give the iframe the required height and width
  document.getElementById("wysiwyg" + n).style.height = wyzzH + "px";
  document.getElementById("wysiwyg" + n).style.width = wyzzW + "px";
	
  // Pass the textarea's existing text into the editor
  var content = document.getElementById(n).value;
  var doc = document.getElementById("wysiwyg" + n).contentWindow.document;
	
  // Write the textarea's content into the iframe
  doc.open();
  if (browserName == "Microsoft Internet Explorer") {
      doc.write('<link rel="stylesheet" media="screen" type="text/css" href="' + editstyle + '"/>' + content);
    } else {
      doc.write('<html><head><link rel="stylesheet" type="text/css" href="' + editstyle + '"/></head><body>' + content + '<br /></body></html>');
    }
  doc.close();

//  var browserName = navigator.appName;
  if (browserName == "Microsoft Internet Explorer"||browserName == "Opera") {    
    // Make the iframe editable
    doc.body.contentEditable = true;
  } else {
    // Make the iframe editable
    doc.designMode = "on";  
  }
	
  // Update the textarea with content in WYSIWYG when user submits form
  // var browserName = navigator.appName;
  if (browserName == "Microsoft Internet Explorer"||browserName == "Opera") {
    for (var idx=0; idx < document.forms.length; idx++) {
      document.forms[idx].attachEvent('onsubmit', function() { updateTextArea(n); });
    }
  }
  else {
  	for (var idx=0; idx < document.forms.length; idx++) {
    	document.forms[idx].addEventListener('submit',function OnSumbmit() { updateTextArea(n); }, true);
    }
  }
}

function formatTextColor(color, n, selected) {
  document.getElementById('wysiwyg' + n).contentWindow.document.execCommand('forecolor', false, color);
  document.getElementById('colorpicker' + n).style.display = "none";		
}

function formatBackColor(color, n, selected) {
  if (browserName == "Microsoft Internet Explorer") {
    document.getElementById('wysiwyg' + n).contentWindow.document.execCommand('backcolor', false, color);
  } else {
    document.getElementById('wysiwyg' + n).contentWindow.document.execCommand('hilitecolor', false, color);
  }
  document.getElementById('colorbackpicker' + n).style.display = "none";	
}

function formatFontName(fontname, n, selected) {
  document.getElementById('wysiwyg' + n).contentWindow.document.execCommand('fontName', false, fontname);
  document.getElementById('fontpicker' + n).style.display = "none";	
}

function formatSpecialChar(charname, n, selected) {
  insertHTML(charname, n);
  document.getElementById('specialpicker' + n).style.display = "none";	
}

function formatHeader(headername, n, selected) {
  document.getElementById('wysiwyg' + n).contentWindow.document.execCommand('formatBlock', false, '<'+headername+'>');
  document.getElementById('headerpicker' + n).style.display = "none";	
}

function formatText(id, n, selected) {
  if(mode==0&&id!='htmlmode') {
    alert('Function unavailable in "View Source" mode');
  } else {
    // When user clicks button make sure it always targets correct textarea
    document.getElementById("wysiwyg" + n).contentWindow.focus();	
    if(id=="upsize") {
      var currentFontSize = document.getElementById("wysiwyg"+n).contentWindow.document.queryCommandValue("FontSize");
      if(currentFontSize == ''||!currentFontSize) currentFontSize = 3; // fudge for FF
        if(currentFontSize < 7) {
          var newFontSize = parseInt(currentFontSize) + 1;
        } else {
          var newFontSize = currentFontSize;
        }
        document.getElementById("wysiwyg" + n).contentWindow.document.execCommand("FontSize", false, newFontSize);
      }
    else if(id=="downsize") {
      var currentFontSize = document.getElementById("wysiwyg"+n).contentWindow.document.queryCommandValue("FontSize");
      if(currentFontSize > 1) {
          var newFontSize = currentFontSize - 1;
        } else {
          var newFontSize = currentFontSize;
        }
        document.getElementById("wysiwyg" + n).contentWindow.document.execCommand("FontSize", false, newFontSize);
      }
      else if(id=="forecolor"){
        if(document.getElementById('colorpicker' + n).style.display == ""){
          document.getElementById('colorpicker' + n).style.display = "none";
        } else {
          document.getElementById('colorpicker' + n).style.display = "";	
        }
      } 
      else if(id=="backcolor"){
        if(document.getElementById('colorbackpicker' + n).style.display == ""){
          document.getElementById('colorbackpicker' + n).style.display = "none";
        } else {
            document.getElementById('colorbackpicker' + n).style.display = "";	
        }
      }
      else if(id=="font"){
        if(document.getElementById('fontpicker' + n).style.display == ""){
          document.getElementById('fontpicker' + n).style.display = "none";
        } else {
          document.getElementById('fontpicker' + n).style.display = "";	
        }
      } 
      else if(id=="specialchar"){
        if(document.getElementById('specialpicker' + n).style.display == ""){
          document.getElementById('specialpicker' + n).style.display = "none";
        } else {
          document.getElementById('specialpicker' + n).style.display = "";	
        }
      }     
      else if(id=="headers"){
        if(document.getElementById('headerpicker' + n).style.display == ""){
          document.getElementById('headerpicker' + n).style.display = "none";
        } else {
          document.getElementById('headerpicker' + n).style.display = "";	
        }
      } 
      else if(id=="htmlmode"){		
        var getDoc = document.getElementById("wysiwyg" + n).contentWindow.document;      
        if(mode == 1) {
          if(navigator.appName == "Microsoft Internet Explorer"||browserName == "Opera") {
            var iHTML = getDoc.body.innerHTML;
            getDoc.body.innerText = iHTML;
          } else {
            var html = document.createTextNode(getDoc.body.innerHTML);
            getDoc.body.innerHTML = "";
            getDoc.body.appendChild(html);
          }
          getDoc.body.style.fontSize = "12px";
          getDoc.body.style.fontFamily = "Courier New";
          mode = 0;
        } else {
          if(navigator.appName == "Microsoft Internet Explorer"||browserName == "Opera") {
            var iText = getDoc.body.innerText;
            getDoc.body.innerHTML = iText;
          } else {
            var html = getDoc.body.ownerDocument.createRange();
            html.selectNodeContents(getDoc.body);
            getDoc.body.innerHTML = html.toString();
          }
          mode = 1;        
        }
      }
      else if(id=="help"){	
        if(document.getElementById('helpbox' + n).style.display == ""){
          document.getElementById('helpbox' + n).style.display = "none";
        } else {
          document.getElementById('helpbox' + n).style.display = "";	
        }    
      }
      else if(id=="link"){
        // var browserName = navigator.appName;	 	 
        if (browserName == "Microsoft Internet Explorer") {  
          var target = confirm('Should this link open in a new window?\n\nOK = Open in NEW Window\nCancel = Open in THIS window');
          document.getElementById("wysiwyg" + n).contentWindow.document.execCommand('createLink',true,' ');
          if(target == true)
          {
            document.getElementById("wysiwyg" + n).contentWindow.document.selection.createRange().parentElement().target="_blank";
          }
        } else {
          insertLink(n);
        }
      }
      else if(id=="insertimage") {
        // var browserName = navigator.appName;	 	 
        if (browserName == "Microsoft Internet Explorer") {       
          document.getElementById("wysiwyg" + n).contentWindow.document.execCommand(id, true, null);
        } else {
          insertImage(n);
        }
      }
      else {
        document.getElementById("wysiwyg" + n).contentWindow.document.execCommand(id, false, null);
    }
  }
}

function insertHTML(html, n) {
  // var browserName = navigator.appName;	 	 
	if (browserName == "Microsoft Internet Explorer") {	  
	  document.getElementById('wysiwyg' + n).contentWindow.document.selection.createRange().pasteHTML(html);   
	} 
	 
	else {
	  var div = document.getElementById('wysiwyg' + n).contentWindow.document.createElement("span");
		 
		div.innerHTML = html;
		var node = insertNodeAtSelection(div, n);		
	}
}

function insertNodeAtSelection(insertNode, n) {
  // get current selection
  var sel = document.getElementById('wysiwyg' + n).contentWindow.getSelection();

  // get the first range of the selection (there's almost always only one range)
  var range = sel.getRangeAt(0);

  // deselect everything
  sel.removeAllRanges();

  // remove content of current selection from document
  range.deleteContents();

  // get location of current selection
  var container = range.startContainer;
  var pos = range.startOffset;

  // make a new range for the new selection
  range = document.createRange();

  if (container.nodeType==3 && insertNode.nodeType==3) {

    // if we insert text in a textnode, do optimized insertion
    container.insertData(pos, insertNode.nodeValue);

    // put cursor after inserted text
    range.setEnd(container, pos+insertNode.length);
    range.setStart(container, pos+insertNode.length);
  } 
	
	else {
    var afterNode;
    
		if (container.nodeType==3) {
      // when inserting into a textnode we create 2 new textnodes and put the insertNode in between
      var textNode = container;
      container = textNode.parentNode;
      var text = textNode.nodeValue;

      // text before the split
      var textBefore = text.substr(0,pos);

      // text after the split
      var textAfter = text.substr(pos);

      var beforeNode = document.createTextNode(textBefore);
      afterNode = document.createTextNode(textAfter);

      // insert the 3 new nodes before the old one
      container.insertBefore(afterNode, textNode);
      container.insertBefore(insertNode, afterNode);
      container.insertBefore(beforeNode, insertNode);

      // remove the old node
      container.removeChild(textNode);
    } 
	
	  else {
      // else simply insert the node
      afterNode = container.childNodes[pos];
      container.insertBefore(insertNode, afterNode);
    }

    range.setEnd(afterNode, 0);
    range.setStart(afterNode, 0);
  }

  sel.addRange(range);
}

function updateTextArea(n) {
  if(xhtml_out == 1) {
    document.getElementById(n).value = h2x(document.getElementById("wysiwyg" + n).contentWindow.document.body);
  } else {
    document.getElementById(n).value = document.getElementById("wysiwyg" + n).contentWindow.document.body.innerHTML;
  }       
}
  

function grabSelectedText(n){ 
   // var browserName = navigator.appName; 
   var selectedText = ''; 
   // for IE 
   if (browserName == "Microsoft Internet Explorer"||browserName == "Opera") { 
      var theText = document.getElementById("wysiwyg" + n).contentWindow.document.selection; 
      if(theText.type =='Text')   { 
         var newText = theText.createRange(); 
         selectedText = newText.text; 
      } 
   } 
   // for Mozilla/Netscape 
   else { 
      var selectedText = document.getElementById("wysiwyg" + n).contentWindow.document.getSelection(); 
   } 
   return selectedText; 
} 

/*var myrules = {
		'input[type=submit]' : function(element){
			element.onclick = function(){
				// Your onclick event goes here - eg;
				// load a page - do an AJAX etc.;
			}
		}
	};
	
Behaviour.register(myrules);*/
