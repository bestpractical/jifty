/**
 * This file overrides functions defined in Interface Elements for jQuery (http://interface.eyecon.ro)
 * so they can work with Jifty. It must be loaded after all Interface scripts, and better before
 * jquery_noconflict.js
 */

jQuery.iAuto.update = function() {
    var subject = jQuery.iAuto.subject;
    var subjectValue = jQuery.iAuto.getFieldValues(subject);
    //var selectionStart = jQuery.iAuto.getSelectionStart(subject);
    if (subject && subjectValue.item != jQuery.iAuto.lastValue && subjectValue.item.length >= subject.autoCFG.minchars) {
	jQuery.iAuto.lastValue = subjectValue.item;
	jQuery.iAuto.currentValue = subjectValue.item;

        var request = Jifty.current_autocompleter_object.buildRequest();
	jQuery.ajax(
	    {
		'type': 'post',
		'url': subject.autoCFG.source,
                'contentType': 'text/x-json',
		'data': JSON.stringify(request),
                'dataType': 'xml',
		'success': function(xml, textStatus) {
		    subject.autoCFG.lastSuggestion = jQuery('li',xml);
		    size = subject.autoCFG.lastSuggestion.size();
		    if (size > 0) {
			var toWrite = '';

			subject.autoCFG.lastSuggestion.each(
			    function(nr) {
                                // XXX: we should be looking at span.hidden_value, but it doesn't exist... 
                                var v = jQuery(this).text();
                                var value = v;
                                if (jQuery('span:last', this).size()) {
                                    value = jQuery('span:last', this).text();
                                    // XXX for some reasons .html() / innerHTML is empty though we have .text() working, so reconstruct the bloody html
                                    v = '<span class="informal">'+jQuery('span:first', this).text()+'</span>'+'<span class="hidden_value">'+jQuery('span:last', this).text()+'</span>';
                                }

				toWrite += '<li rel="' + value + '" dir="' + nr + '" style="cursor: default;">' + v + '</li>';
			    }
			);
                        
			if (subject.autoCFG.autofill) {
			    var valueToAdd = jQuery('value', subject.autoCFG.lastSuggestion.get(0)).text();
			    subject.value = subjectValue.pre + valueToAdd + subject.autoCFG.multipleSeparator + subjectValue.post;
			    jQuery.iAuto.selection(
				subject, 
				subjectValue.item.length != valueToAdd.length ? (subjectValue.pre.length + subjectValue.item.length) : valueToAdd.length,
				subjectValue.item.length != valueToAdd.length ? (subjectValue.pre.length + valueToAdd.length) : valueToAdd.length
			    );
			}

			if (size > 0) {
			    jQuery.iAuto.writeItems(subject, toWrite);
			} else {
			    jQuery.iAuto.clear();
			}
		    } else {
			jQuery.iAuto.clear();
		    }
		}
	    }
	);
    }
};

jQuery.fn.shake = function() {
    this.each(function(init) {
        var e = jQuery(this);
        e.css('position', 'relative');
        for (var i = 1; i < 5; i++) {
            e.animate({ left: -20/i }, 50)
             .animate({ left: 0 },     50)
             .animate({ left: 20/i },  50)
             .animate({ left: 0 },     50);
        }
    });
    return this;
};

