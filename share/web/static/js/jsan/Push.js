/*

*/

if (typeof(HTTP) == "undefined") { HTTP = {}; }

HTTP.Push = {};
HTTP.Push.VERSION = '0.04';

/*

*/

HTTP.Push = function(args) {
  if (args == undefined) { throw "Push must be passed an argument hash!"; }
  if (args.uri == undefined) { throw "Must specify push URI!"; }
  if (args.onPush == undefined) { throw "Must specify onPush handler!"; }
  if (args.interval == undefined) { args.interval = 100; }


  var body = document.getElementsByTagName("body")[0];
  var iframe = document.createElement("iframe");
  iframe.style.border = "0px";
  iframe.style.height = "0px";
  iframe.style.width = "0px";
  iframe.src = args.uri;

  var interval = undefined;

/*

*/

  this.start = function() {
    body.appendChild(iframe);
    interval = setInterval(function() { flushIframe(); }, args.interval);
  }


// TODO: make the stop function work in IE
//   this.stop = function() {
//     body.removeChild(iframe);
//     clearInterval(interval);
//   }


  function flushIframe() {
    var doc;
    if (iframe.contentDocument) {          // For NS6
      doc = iframe.contentDocument;
    } else if (iframe.contentWindow) {     // For IE5.5 and IE6
      doc = iframe.contentWindow.document;
    } else if (iframe.document) {          // For IE5
      doc = iframe.document;
    } else {
      return;
    }
  
    var body = doc.body;
  
    while (body && body.hasChildNodes()) {
      var node = body.firstChild;
      try {
         args.onPush(node);
      }
      catch (e) { };
      body.removeChild(node);
    }
  }

  return this;
}

/*

*/
