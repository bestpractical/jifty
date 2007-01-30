// CSS Browser Selector   v0.4
// Documentation:         http://rafael.adm.br/css_browser_selector
// License:               http://creativecommons.org/licenses/by/2.5/
// Author:                Rafael Lima (http://rafael.adm.br)
// Contributors:          http://rafael.adm.br/css_browser_selector#contributors
function css_browser_selector() {
	var ua = navigator.userAgent.toLowerCase(); 
	var h = document.getElementsByTagName('html')[0];
	if(ua.indexOf('msie') != -1 && !(ua.indexOf('opera') != -1) && (ua.indexOf('webtv') == -1) ) h.className='ie';
	else if(ua.indexOf('gecko/') != -1) h.className='gecko';
	else if(ua.indexOf('opera') != -1) h.className='opera';
	else if(ua.indexOf('konqueror') != -1) h.className='konqueror';
	else if(ua.indexOf('applewebkit/') != - 1) h.className='safari';
}
css_browser_selector();