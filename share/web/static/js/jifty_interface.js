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
		type: 'post',
		data: JSON.stringify(request),
		success: function(xml)
		{
		    subject.autoCFG.lastSuggestion = jQuery('li',xml);
		    size = subject.autoCFG.lastSuggestion.size();
		    if (size > 0) {
			var toWrite = '';

			subject.autoCFG.lastSuggestion.each(
			    function(nr) {
                                var v = jQuery(this).text();
				toWrite += '<li rel="' + v + '" dir="' + nr + '" style="cursor: default;">' + v + '</li>';
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
		},
                beforeSend: function(xhr) {
                    xhr.setRequestHeader('Content-Type', 'text/x-json');
                },
		url : subject.autoCFG.source
	    }
	);
    }
};
