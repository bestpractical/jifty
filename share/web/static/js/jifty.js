/* An empty class so we can create things inside it */
var Jifty = {};

// to add a response_hook
// the handler will get two arguments:
//
// response_fragment:
//     - response xml dom object
//
// f:
//     - 'region' is the name of the region to update
//     - 'args' is a hash of arguments to override
//     - 'path' is the path of the fragment (if this is a new fragment)
//     - 'element' is the CSS selector of the element to update, if 'region' isn't supplied
//     - 'mode' is one of 'Replace', 'Top', 'Bottom', 'Before', or 'After'
//     - 'effect' is the name of an effect
//
Jifty.Update = {
    response_hooks: [],
    handler_hooks: [],
    addHook:function(f){
        this.response_hooks.push(f);
    }
};

Jifty.$ = function(id) {
    if (typeof id == 'string')
        return document.getElementById(id)
    return id;
}

Jifty.hasAjaxTransport = function() {
    var r = false;
    jQuery.each(
        [
            function() {return new XMLHttpRequest()},
            function() {return new ActiveXObject('Msxml2.XMLHTTP')},
            function() {return new ActiveXObject('Microsoft.XMLHTTP')}
        ],
        function(i, v) {
            try {
                r = v();
                if (r) return false;
            } catch(e) {}
        })
    return r ? true : false;
}();

Jifty.stopEvent = function(ev) {
    jQuery.event.fix(ev);
    ev.preventDefault();
    ev.stopPropagation();
};

Jifty.Web = {};
Jifty.Web.current_actions = [];

function register_action(a) {
    outs(div(function() {
                attr(function() { return ['class', 'hidden'] });
                return input(function() { attr(function() {
                                return ['type', 'hidden',
                                        'name', a.register_name(),
                                        'id', a.register_name(),
                                        'value', a.actionClass] }) } ) } ));
    /* XXX: fallback values */
}

/* Actions */
var Action = function() {
    this.initialize.apply(this, arguments);
    return this;
};

Action.prototype = {
    // New takes the moniker (a string), and an optional array of form
    // elements to additionally take into consideration
    initialize: function(moniker) {
        this.moniker = moniker;

        // Extra form parameters
        this.extras = [];
        if (arguments.length > 1) {
            this.extras = arguments[1];
        }

        this.register = Jifty.$('J:A-' + this.moniker); // Simple case -- no ordering information
        if (! this.register) {
            var elements = [];
            // We need to go looking -- this also goes looking through this.extras, from above

            var add_to_elements = function(){ elements.push(this) };
            jQuery('input').each(add_to_elements);
            jQuery.each(this.extras, add_to_elements);

            for (var i = 0, l = elements.length; i < l; i++) {
                if ((Jifty.Form.Element.getMoniker(elements[i]) == this.moniker)
                    && (Jifty.Form.Element.getType(elements[i]) == "registration")) {
                    this.register = elements[i];
                    break;
                }
            }
        }

        if (this.register) {
            this.form = Jifty.Form.Element.getForm(this.register);
            this.actionClass = this.register.value;
        }
    },

    // Returns an Array of all fields in this Action
    fields: function() {
        if(!this.cached_fields) {
            var elements = [];
            var possible = Jifty.Form.getElements(this.form);
            // Also pull from extra query parameters
            for (var i = 0, l = this.extras.length; i < l; i++)
                possible.push(this.extras[i]);

            for (var i = 0, l = possible.length; i < l; i++) {
                if (Jifty.Form.Element.getMoniker(possible[i]) == this.moniker)
                    elements.push(possible[i]);
            }
            this.cached_fields = elements;
        }
        return this.cached_fields;
    },

    buttons: function() {
        var elements = new Array();
        var possible = Jifty.Form.getElements(this.form);
        for(var i = 0; i < possible.length; i++) {
            if(possible[i].nodeName == 'INPUT' && possible[i].getAttribute("type") == 'submit') {
                actions = Jifty.Form.Element.buttonActions(possible[i]);
                //If the button has no actions explicitly associated
                //with it, it's associated with all the actions in the
                //form
                if(   actions.length == 0
                   || actions.indexOf(this.moniker) >= 0) {
                    elements.push(possible[i]);
                }
            }
        }
        return elements;
    },

    getField: function(name) {
        var elements = this.fields();
        for (var i = 0; i < elements.length; i++) {
            if (Jifty.Form.Element.getField(elements[i]) == name)
                return elements[i];
        }
        return null;
    },

    // Serialize and return all fields needed for this action
    serialize: function() {
        var fields = this.fields();
        var serialized = new Array;

        jQuery.each(fields, function() {
            serialized.push( jQuery(this).serialize() )
        });

        return serialized.join('&');
    },

    // Returns true if there is a file upload form as one of our elements
    hasUpload: function() {
        var fields = this.fields();
        for (var i = 0, l = fields.length; i < l; i++) {
            if ((fields[i].getAttribute("type") == "file") && fields[i].value)
                return true;
        }
        return false;
    },

    // Return the action as a data structure suitable to be JSON'd
    data_structure: function() {
        var a = {};
        a['moniker'] = this.moniker;
        a['class']   = this.actionClass;

        if (this.register && this.register.id) {
            var tmp = this.register.id.match(/^J:A-(\d+)-/);
            if (tmp && tmp.length == 2)
                a['order'] = tmp[1];
        }

        a['fields']  = {};
        var fields = this.fields();
        for (var i = 0; i < fields.length; i++) {
            var f = fields[i];

            if (   (Jifty.Form.Element.getType(f) != "registration")
                && (Jifty.Form.Element.getValue(f) != null)
                && (!Jifty.Placeholder.hasPlaceholder(f)))
            {
                if (! a['fields'][Jifty.Form.Element.getField(f)])
                    a['fields'][Jifty.Form.Element.getField(f)] = {};
                var field = Jifty.Form.Element.getField(f);
                var type = Jifty.Form.Element.getType(f);

                // XXX: fallback value being an array makes server
                // upset, we don't think that should happen anyway
                if (type == 'fallback' && a['fields'][field][type])
                    continue
                a['fields'][field][type] = this._mergeValues(a['fields'][field][type],
                                                             Jifty.Form.Element.getValue(f));

            }
        }

        return a;
    },

    _mergeValues: function() {
        var oldval = arguments[0];
        var newval = arguments[1];
        if(!oldval) return newval;
        if(oldval.constructor != Array) {
            oldval = [oldval];
        }
        oldval.push(newval);
        return oldval;
    },

    // Validate the action
    validate: function() {
        show_wait_message();
        var id = this.register.id;

        var data = this.serialize();
        data += '&J:VALIDATE=1';
        if (this.form['J:C']) {
            data += '&J:C='+this.form['J:C'].value;
        }

        jQuery.ajax({
            url: '/__jifty/validator.xml',  // Right now, the URL is actually completely irrelevant
            type: "get",
            data: data,
            complete: function (request, status) {
                var response  = request.responseXML.documentElement;
                for (var action = response.firstChild; action != null; action = action.nextSibling) {
                    if ((action.nodeName == 'validationaction') && (action.getAttribute("id") == id)) {
                        for (var field = action.firstChild; field != null; field = field.nextSibling) {
                            // Possibilities for field.nodeName: it could be #text (whitespace),
                            // or 'blank' (the field was blank, don't mess with the error div), or 'ok'
                            // (clear the error and warning div!) or 'error' (fill in the error div, clear
                            // the warning div!) or 'warning' (fill in the warning div and clear the error div!)
                            if (field.nodeName == 'error' || field.nodeName == 'warning') {
                                var err_div = document.getElementById(field.getAttribute("id"));
                                if (err_div != null) {
                                    jQuery(err_div).show().html(field.firstChild.data);
                                }
                            } else if (field.nodeName == 'ok') {
                                var err_div = document.getElementById(field.getAttribute("id"));
                                if (err_div != null) {
                                    jQuery(err_div).hide().html('');
                                }
                            }
                        }
                    } else if ((action.nodeName == 'canonicalizeaction') && (action.getAttribute("id") == id)) {
                        for (var field = action.firstChild; field != null; field = field.nextSibling) {
                            // Possibilities for field.nodeName: it could be 'ignored', 'blank' , 'update', or 'info'
                            // info is a separate action from the update
                            if (field.nodeName == 'canonicalization_note')  {
                                var note_div= document.getElementById(field.getAttribute("id"));
                                if (note_div != null) {
                                    jQuery(note_div).show().html(field.firstChild.data);
                                }
                            }

                            if (field.nodeName == 'update') {
                                var field_name = field.getAttribute("name");
                                for (var form_number = 0 ; form_number < document.forms.length; form_number++) {
                                    var form_field = document.forms[form_number].elements[field_name];
                                    if (form_field  == null || !jQuery(form_field).is('.ajaxcanonicalization'))
                                        continue;
                                    form_field.value = field.firstChild.data;
                                }
                            }
                        }
                    }
                }
                return true;
            }            
        });
        
        hide_wait_message();
        return false;
    },

    submit: function() {
        show_wait_message();
        jQuery.ajax({
            url: '/empty',
            type: 'post',
            data: this.serialize()
        });
        hide_wait_message();
    },

    disable_input_fields: function(disabled_elements) {
        var disable = function() {
            var elt = this;
            // Disabling hidden elements seems to  make IE sad for some reason
            if(elt.type != 'hidden') {
                // Triggers https://bugzilla.mozilla.org/show_bug.cgi?id=236791
                elt.blur();
                elt.disabled = true;
                disabled_elements.push(elt);
            }
        };
        jQuery.each(this.fields(), disable);
        jQuery.each(this.buttons(), disable);
    },

    enable_input_fields: function() {
        var enable = function() { this.disabled = false; };
        jQuery.each(this.fields(), disable);
        jQuery.each(this.buttons(), disable);
    },


    /* client side logic extracted from Jifty::Action */
    _action_spec: function() {
        if (!this.s_a) {
            /* XXX: make REST client accessible */
            var Todo = new AsynapseRecord('todo');
            this.s_a = jQuery.extend({}, Todo.eval_ajax_get('/=/action/'+this.actionClass+'.js'));
        }

        return this.s_a
    },
    argument_names: function() {
        return this._action_spec().keys();
    },

    render_param: function(field) {
        var a_s = this._action_spec();
        var type = 'text';
        var f = new ActionField(field, a_s[field], this);
        return f.render();
    },
    register_name: function() { return this.register.id }

};

var SERIAL_postfix = Math.ceil(10000*Math.random());
var SERIAL = 0;
var ActionField = function() {
    this.initialize.apply(this, arguments);
    return this;
};

ActionField.prototype = {
 initialize: function(name, args, action) {
        this.name = name;
        this.label = args.label;
        this.hints = args.hints;
        this.mandatory = args.mandatory;
        this.ajax_validates = args.ajax_validates;
        this.current_value = action.data_structure().fields[name].value;
        this.error = action.result.field_error[name];
        this.action = action;
        if (!this.render_mode) this.render_mode = 'update';
        this.type = 'text';
    },

 render: function() {
        if (this.render_mode == 'read')
            return this.render_wrapper
                (this.render_preamble,
                 this.render_label,
                 this.render_value);
        else
            return this.render_wrapper
            (this.render_preamble,
             this.render_label,
             this.render_widget,
             this.render_autocomplete_div,
             this.render_inline_javascript,
             this.render_hints,
             this.render_errors,
             this.render_warnings,
             this.render_canonicalization_notes);
    },
 render_wrapper: function () {
        var classes = ['form_field'];
        if (this.mandatory) classes.push('mandatory');
        if (this.name) classes.push('argument-'+this.name);
        var args = arguments;
        var tthis = this;
        return div(function() {
                attr(function(){return ['class', classes.join(' ')]});
                var buf = new Array;
                for (var i = 0; i < args.length; ++i) {
                    buf.push(typeof(args[i]) == 'function' ? args[i].apply(tthis) : args[i]);
                }
                return buf.join('');
            });
    },
    render_preamble: function() {
        var tthis = this;
        return span(function(){attr(function(){return ['class', "preamble"]});
                return tthis.preamble });
    },

    render_label: function() {
        var tthis = this;
        if(this.render_mode == 'update')
            return label(function(){attr(function(){return['class', "label", 'for', tthis.element_id()]});
                    return tthis.label });
        else
            return span(function(){attr(function(){return['class', "label" ]});
                    return tthis.label });
    },
 input_name: function() {
        return ['J:A:F', this.name, this.action.moniker].join('-');
    },
 render_hints: function() {
        var tthis = this;
        return span(function(){attr(function(){return ['class', "hints"]});
                return tthis.hints });
    },

 render_errors: function() {
        if (!this.action) return '';
        var tthis = this;
        // XXX: post-request handler needs to extract field error messages
        return span(function(){attr(function(){return ['class', "error", 'id', 'errors-'+tthis.input_name()]});
                return tthis.error });
    },

 render_widget: function () {
        var tthis = this;
        return input(function(){
                    attr(function(){
                            var fields = ['type', tthis.type];
                            if (tthis.input_name) fields.push('name', tthis.input_name());
                            fields.push('id', tthis.element_id());
                            if (tthis.current_value) fields.push('value', tthis.current_value);
                            fields.push('class', tthis._widget_class().join(' '));
                            if (tthis.display_length) {
                                fields.push('size', tthis.display_length)
                            }
                            else if (tthis.max_length) {
                                fields.push('size', tthis.max_length)
                            }

                            if (tthis.max_length) fields.push('maxlength', tthis.max_length);
                            if (tthis.disable_autocomplete) fields.push('autocomplete', "off");
                            //" " .$self->other_widget_properties;
                            return fields;
                        })});
    },
 _widget_class: function() {
        var classes = ['form_field'];
        if (this.mandatory)      classes.push('mandatory');
        if (this.name)           classes.push('argument-'+this.name);
        if (this.ajax_validates) classes.push('ajaxvalidation');
        return classes;
    },

 element_id: function() { if(!this._element_id) this._element_id = this.input_name() + '-S' + (++SERIAL + SERIAL_postfix);
                          return this._element_id; },
 __noSuchMethod__: function(name) {
        return '<!-- '+name+' not implemented yet -->';
    }

};

/* Forms */

Jifty.Form = {};

jQuery.extend(Jifty.Form, {
    getElements: function(element) {
        return jQuery(":input", element).get();
    },

    // Return an Array of Actions that are in this form
    getActions: function (element) {
        var elements = [];

        jQuery(":input", element).each(function() {
            if (Jifty.Form.Element.getType(this) == "registration")
                elements.push(Jifty.Form.Element.getAction(this));
        });

        return elements;
    },

    clearPlaceholders: function(element) {
        var elements = Jifty.Form.getElements(element);
        for(var i = 0; i < elements.length; i++) {
            Jifty.Placeholder.clearPlaceholder(elements[i]);
        }
    }
});

var current_actions = {};

Jifty.Form.Element = {};

/* Fields */

jQuery.extend(Jifty.Form.Element, {
    // Get the moniker for this form element
    // Takes an element or an element id
    getMoniker: function (element) {
        element = Jifty.$(element);
        
        if (/^J:A(:F)+-[^-]+-.+$/.test(element.name)) {
            var bits = element.name.match(/^J:A(?::F)+-[^-]+-(.+)$/);
            return bits[1];
        } else if (/^J:A-(\d+-)?.+$/.test(element.name)) {
            var bits = element.name.match(/^J:A-(?:\d+-)?(.+)$/);
            return bits[1];
        } else {
            return null;
        }
    },

    // Get the Action for this form element
    // Takes an element or an element id
    getAction: function (element) {
        element = Jifty.$(element);
        var moniker = Jifty.Form.Element.getMoniker(element);
        if (!current_actions[moniker])
            current_actions[moniker] = new Action(moniker);
        return current_actions[moniker];
    },

    // Returns the name of the field
    getField: function (element) {
        element = Jifty.$(element);

        if (/^J:A(:F)+-[^-]+-.+$/.test(element.name)) {
            var bits = element.name.match(/^J:A(?::F)+-([^-]+)-.+$/);
            return bits[1];
        } else {
            return null;
        }
    },

    // The type of Jifty form element
    getType: function (element) {
        element = Jifty.$(element);
        if (/^J:A-/.test(element.name)) {
            return "registration";
        } else if (/^J:A:F-/.test(element.name)) {
            return "value";
        } else if (/^J:A:F:F-/.test(element.name)) {
            return "fallback";
        } else {
            return null;
        }
    },

    getValue: function(element) {
        var $el = jQuery(Jifty.$(element));
        if ( $el.is(":checkbox, :radio") ) {
            return $el.is(":checked") ? $el.val() : null
        }
        return $el.val();
    },

    // Validates the action this form element is part of
    validate: function (element) {
        if ( !jQuery(element).is('.validation_disabled') ) {
            Jifty.Form.Element.getAction(element).validate();
        }
    },

    // Temporarily disable validation
    disableValidation: function(element) {
        jQuery(element).addClass('validation_disabled');
    },

    //Reenable validation
    enableValidation: function(element) {
        jQuery(element).removeClass('validation_disabled');
    },


    // Look up the form that this element is part of -- this is sometimes
    // more complicated than you'd think because the form may not exist
    // anymore, or the element may have been inserted into a new form.
    // Hence, we may need to walk the DOM.
    getForm: function (element) {
        element = Jifty.$(element);

        if (!element)
            return null;

        if (element.virtualform)
            return element.virtualform;

        if (element.form)
            return element.form;

        for (var elt = element.parentNode; elt != null; elt = elt.parentNode) {
            if (elt.nodeName == 'FORM') {
                element.form = elt;
                return elt;
            }
       }
        return null;
    },

    buttonArguments: function(element) {
        element = Jifty.$(element);
        if (!element)
            return {}

        if (((element.nodeName != 'INPUT') || (element.getAttribute("type") != "submit"))
         && ((element.nodeName != 'A')     || (! element.getAttribute("name"))))
            return {}

        if (element.getAttribute("name").length == 0)
            return {}

        var extras = {}

        // Split other arguments out, if we're on a button
        var pairs = element.getAttribute("name").split("|");
        for (var i = 0; i < pairs.length; i++) {
            var bits = pairs[i].split('=',2);
            extras[ bits[0] ] = bits[1];
        }
        return extras;
    },

    buttonActions: function(element) {
        element = Jifty.$(element);
        var actions = Jifty.Form.Element.buttonArguments(element)['J:ACTIONS'];
        if(actions) {
            return actions.split(",");
        } else {
            return new Array();
        }
    },

    buttonFormElements: function(element) {
        element = Jifty.$(element);

        var extras = [];
        if (!element)
            return extras;

        var args = Jifty.Form.Element.buttonArguments(element);

        jQuery.each(args, function(k, v) {
            var e = document.createElement("input");
            e.setAttribute("type", "hidden");
            e.setAttribute("name", k);
            e.setAttribute("value", v);
            e['virtualform'] = Jifty.Form.Element.getForm(element);
            extras.push(e);
        });

        return extras;
    },

    /* Someday Jifty may have the concept of "default"
       buttons.  For now, this clicks the first button that will
       submit the action associated with the form element.
     */
    clickDefaultButton: function(element) {
        var action = Jifty.Form.Element.getAction( element );
        if ( action ) {
            var buttons = action.buttons();
            for ( var i = 0; i < buttons.length; i++ ) {
                var b = buttons[i];
                if ( Jifty.Form.Element.buttonActions( b ).indexOf( action.moniker ) >= 0 ) {
                    b.click();
                    return true;
                }
            }
        }
        return false;
    },

    handleEnter: function(event) {
        /* Trap "Enter" */
        if (    event.keyCode == 13
             && !event.metaKey && !event.altKey && !event.ctrlKey )
        {
            if ( Jifty.Form.Element.clickDefaultButton( event.target ) )
                event.preventDefault();
        }
    }

});

// Form elements should AJAX validate if the CSS says so
Behaviour.register({
    'input.ajaxvalidation, textarea.ajaxvalidation, input.ajaxcanonicalization, textarea.ajaxcanonicalization': function(elt) {
        jQuery(elt).bind('blur', function () {
            Jifty.Form.Element.validate(elt);
        });
    },
    'input.date': function(e) {
        if ( !jQuery(e).hasClass('has_calendar_link') ) {
            createCalendarLink(e);
            jQuery(e).addClass('has_calendar_link');
        }
    },
    'input.time': function(e) {
        jQuery(e).timepickr({handle: jQuery(e)});
    },
    'input.datetime': function(e) {
        if ( !jQuery(e).hasClass('has_datetime_link') ) {
            createDateTimeLink(e);

            var button = document.createElement('input');
            button.setAttribute('type',  'button');
            jQuery(button).insertAfter(e);
            jQuery(button).timepickr({val: 'Pick time'});
            jQuery(button).blur( function() { 
                var old_value = jQuery(this).prev().val();
                if ( Jifty.Calendar.dateRegex.test(old_value) ) {
                    var bits = old_value.match(Jifty.Calendar.dateRegex);
                    old_value = bits[1] + '-' + bits[2] + '-' + bits[3];
                }
                var time = jQuery(button).val();
                jQuery(e).val(  old_value + ' ' + time + ':00' );

                // Trigger an onchange event for any listeners
                jQuery(e).change();
                jQuery(button).val('');
            } 
            );
            jQuery(e).addClass('has_datetime_link');
        }
    },
    'input.button_as_link': function(e) {
        buttonToLink(e);
    },
    "input.date, input.text": function(e) {
        /* XXX TODO: Figure out how to make our enter handler detect
           when the autocomplete is active so we can use it on autocompleted
           fields
         */
        if (   !jQuery(e).hasClass("jifty_enter_handler_attached" )
               && !jQuery(e).hasClass("ajaxautocompletes" )
               && !jQuery(e).hasClass("disable_enter_handler") )
        {
            /* Do not use keydown as the event, it will not work as expected in Safari */
            jQuery(e).bind('keypress', Jifty.Form.Element.handleEnter).addClass("jifty_enter_handler_attached");
        }
    },
    ".messages": function(e) {
        if ( !jQuery(e).hasClass('jifty_enter_handler_attached') ) {
            jQuery(e)
            .prepend('<a  href="#" id="dismiss_'+e.id+'" title="Dismiss" onmousedown="this.onfocus=this.blur;" onmouseup="this.onfocus=window.clientInformation?null:window.undefined" onclick="Jifty.Effect(this.parentNode, \'Fade\'); return false;">Dismiss</a>')
            .addClass("jifty_enter_handler_attached" );

        }
    },
    '.form_field .error, .form_field .warning, .form_field .canonicalization_note': function(e) {
        if ( e.innerHTML == "" ) {
            e.style.display = "none";
        }
    },
    // Form elements should focus if the CSS says so.
    ".focus": function(e) {
        /* Check to see if the element is already focused */
        if (!jQuery(e).hasClass("focused")) {
            jQuery(e).addClass("focused").focus();
        }
    },
    // Hide with javascript (since the user may have even partially-working CSS
    // but no JS)
    ".jshide": function(e) {
        jQuery(e).hide();
    },
    /* Use jQuery for full-page-refresh notifications, as well */
    '#messages.jifty.results.messages, #errors.jifty.results.messages, .popup_message, .popup_error': function(e) {
        jQuery(e).hide();
    },
    '#messages.jifty.results.messages .message, .popup_message': function(e) {
        var sticky = jQuery(e).hasClass('popup_sticky');
        jQuery.jGrowl( e.innerHTML, {
            sticky: sticky,
            theme: 'result-message'
        });
    },
    '#errors.jifty.results.messages .error, .popup_error': function(e) {
        var sticky = jQuery(e).hasClass('popup_sticky');
        jQuery.jGrowl( e.innerHTML, {
            sticky: sticky,
            theme: 'result-error'
        });
    }
});


/* Regions */
// Keep track of the fragments on the page
Jifty.fragments = {};

// Todo: This "fragments" variable should be localized. External access should be restricted
// to use "Jifty.fragments" instead.
var fragments = Jifty.fragments;

var Region = function() {
    this.initialize.apply(this, arguments);
    return this;
};

Region.prototype = {
    initialize: function(name, args, path, parent, in_form) {
        this.name = name;
        this.args = jQuery.extend({}, args);
        this.path = path;
        this.parent = parent ? fragments[parent] : null;
        this.in_form = in_form;
        if (fragments[name]) {
            // If this fragment already existed, we want to wipe out
            // whatever evil lies we might have said earlier; do this
            // by clearing out everything that looks relevant
            jQuery.each(current_args, function(k, v) {
                var parsed = k.match(/^(.*?)\.(.*)/);
                if ((parsed != null) && (parsed.length == 3) && (parsed[1] == this.name)) {
                    current_args[k] = null;
                }                
            });
        }

        fragments[name] = this;
    },

    setPath: function(supplied) {
        var self = this;

        // Merge in from current_args
        jQuery.each(current_args, function(k, v) {
            if (k == self.name) {
                self.path = v
            }
        });

        // Update with supplied
        if (supplied != null) {
            this.path = supplied;
        }

        // Propagate back to current args
        current_args[ this.name ] = this.path;

        // Return new value
        return this.path;
    },

    setArgs: function(supplied) {
        var self = this;
        // Merge in current args
        jQuery.each(current_args, function(k, v) {
            var parsed = k.match(/^(.*?)\.(.*)/);
            if ((parsed != null) && (parsed.length == 3) && (parsed[1] == this.name)) {
                self.args[ parsed[2] ] = v
            }
        });
        // Merge in any supplied parameters
        jQuery.extend(this.args, supplied);

        // Fill supplied parameters into current args
        jQuery.each(supplied, function(k, v) {
            current_args[ self.name + '.' + k ] = v;
        });

        // Return new values
        return this.args;
    },

    data_structure: function(path, args) {
        // Set the path and args, if given
        if (path)
            this.setPath(path);
        if (args)
            this.setArgs(args);

        // If we have a parent, find our not-qualified name
        var shortname = this.name;
        if (this.parent) {
            shortname = this.name.substr(this.parent.name.length + 1);
        }

        // Return a nummy data structure
        return {
            name: shortname,
            path: this.path,
            args: this.args,
            parent: this.parent ? this.parent.data_structure(null,null) : null
        }
    }
};


// Keep track of the state variables.
var current_args = {};

// Prepare element for use in update()
//  - 'fragment' is a hash, see fragments in update()

function prepare_element_for_update(f) {
        var name = f['region'];

        // Find where we are going to go
        var element = document.getElementById('region-' + f['region']);
        if (f['element']) {
            element = jQuery(f['element'])[0];
        }
        f['element'] = element;

        // If we can't find out where we're going, bail
        if (element == null)
            return;

        // If we're removing the element, do it now
        if (f['mode'] == "Delete") {
            fragments[name] = null;
            if (f['effect']) {
                Jifty.Effect(
                    Jifty.$('region-'+f['region']),
                    f['effect'],
                    f['effect_args']
                );
                jQuery(element).queue(function() {
                    jQuery(element).remove();
                    jQuery(element).dequeue();
                });
            } else if (f['remove_effect']) {
                Jifty.Effect(
                    Jifty.$('region-'+f['region']),
                    f['remove_effect'],
                    f['remove_effect_args']
                );
                jQuery(element).queue(function() {
                    jQuery(element).remove();
                    jQuery(element).dequeue();
                });
            } else {
                jQuery(element).remove();
            }
            return;
        }

        f['is_new'] = (fragments[name] ? false : true);
        // If it's new, we need to create it so we can dump it
        if (f['is_new']) {
            // Find what region we're inside
            f['parent'] = null;
            if (f['mode'] && ((f['mode'] == "Before") || (f['mode'] == "After")))
                element = element.parentNode;
            while ((element != null) && (element.getAttribute) && (f['parent'] == null)) {
                if (/^region-/.test(element.getAttribute("id")))
                    f['parent'] = element.getAttribute("id").replace(/^region-/,"");
                element = element.parentNode;
            }

            if (f['parent']) {
                f['region'] = name = f['parent'] + '-' + name;
            }

            // Make the region (for now)
            new Region(name, f['args'], f['path'], f['parent'], f['parent'] ? fragments[f['parent']].in_form : null);
        } else if ((f['path'] != null) && f['toggle'] && (f['path'] == fragments[name].path)) {
            // If they set the 'toggle' flag, and clicking wouldn't change the path
            jQuery(element).empty();
            fragments[name].path = null;
            return;
        } else if (f['path'] == null) {
            // If they didn't know the path, fill it in now
            f['path'] == fragments[name].path;
        }

    return f;
}

var walk_node = function(node, table) {
    for (var child = node.firstChild;
         child != null;
         child = child.nextSibling) {
        var name = child.nodeName.toLowerCase();
        if (table[name])
            table[name](child);
    }
}

// applying updates from a fragment
//   - fragment: the fragment from the server
//   - f: fragment spec
var apply_fragment_updates = function(fragment, f) {
    // We found the right fragment
    var dom_fragment = fragments[ f['region'] ];
    var new_dom_args = {};

    var element = f['element'];
    walk_node(
        fragment,
        {
            argument: function(fragment_bit) {
                // First, update the fragment's arguments
                // with what the server actually used --
                // this is needed in case there was
                // argument mapping going on
                var textContent = '';
                if (fragment_bit.textContent) {
                    textContent = fragment_bit.textContent;
                } else if (fragment_bit.firstChild) {
                    textContent = fragment_bit.firstChild.nodeValue;
                }
                new_dom_args[ fragment_bit.getAttribute("name") ] = textContent;
            },
            content: function(fragment_bit) {
                var textContent = '';
                if (fragment_bit.textContent) {
                    textContent = fragment_bit.textContent;
                } else if (fragment_bit.firstChild) {
                    textContent = fragment_bit.firstChild.nodeValue;
                }

                // Re-arrange all <script> tags to the end of textContent.
                // This approach easily deal with the uncertain amount of
                // time we need to wait before the region is ready for running
                // some javascript.

                var re = new RegExp('<script[^>]*>([\\S\\s]*?)<\/script>', 'img');
                var scripts = (textContent.match(re) || []).join("");
                var textContentWithoutScript = textContent.replace(re, '');
                textContent = textContentWithoutScript + scripts;

                // Once we find it, do the insertion
                if (f['mode'] == 'Popout') {
                    jQuery.facebox(textContent);
                } else if (f['mode'] && (f['mode'] != 'Replace')) {
                    var method = ({
                        After: 'after',
                        Before: 'before',
                        Bottom: 'append',
                        Top: 'prepend'
                    })[ f['mode'] ];

                    jQuery.fn[method].call(jQuery(element), textContent);
                    element = document.getElementById('region-' + f['region']);
                } else if (f['remove_effect']) {
                    Jifty.Effect(
                        Jifty.$('region-'+f['region']),
                        f['remove_effect'],
                        f['remove_effect_args']
                    );
                    jQuery(element).queue(function() {
                        jQuery(element).html( textContent );
                        jQuery(element).dequeue();
                    });
                } else {
                    jQuery(element).html( textContent );
                }
                Behaviour.apply(element);
            }
        }
    );
    dom_fragment.setArgs(new_dom_args);

    // Also, set us up the effect
    if (f['effect']) {
        Jifty.Effect(
            Jifty.$('region-'+f['region']),
            f['effect'],
            f['effect_args'],
            {
                before: function() {
                    if(f['is_new']) 
                        jQuery(this).hide();
                }
            }
        );
    }
}

// Update a region. It takes two arguments.
//
// The first argument is a hash of named parameters, including:
//  - 'actions' is an array of monikers to submit
//  - 'action_arguments' is a hash of action monikers to hashes of arguments which should override any arguments coming from form fields
//        the hash keys for 'action_arguments' are the values of the 'actions' array
//  - 'continuation' is ??? Please document me
//  - 'hide_wait_message' for when you don't want to see it
//  - 'preload' this request is preloading regions
//  - 'preload_key' the cache key for using preloaded regions
//  - 'headers' is a hash of headers to send in this request
//  - 'fragments' is an array of hashes, which may have:
//     - 'region' is the name of the region to update
//     - 'args' is a hash of arguments to override
//     - 'path' is the path of the fragment (if this is a new fragment)
//     - 'element' is the CSS selector of the element to update, if 'region' isn't supplied
//     - 'mode' is one of 'Replace', 'Top', 'Bottom', 'Before', or 'After'
//     - 'effect' is the name of an effect
//
// The second argument is the element (usually a submit button) that triggered
// it.
//
Jifty.update = function () {
    // Let the regular form submit take over if this browser can't do this
    if (!Jifty.hasAjaxTransport) return true;

    // XXX: prevent default behavior in IE
    if(window.event) {
        window.event.returnValue = false;
    }

    // Load the arguments
    var named_args = arguments[0];
    var trigger    = arguments[1];

    // The YAML/JSON data structure that will be sent
    var request = {};

    // Keep track of disabled elements
    var disabled_elements = [];

    // Set request base path
    request.path = '/__jifty/webservices/xml';

    // Grab extra arguments (from a button)
    var button_args = Jifty.Form.Element.buttonFormElements(trigger);

    // Load the form to which this trigger element belongs
    var form = Jifty.Form.Element.getForm(trigger);

    // If the action is null, take all actions
    if (named_args['actions'] == null) {
        named_args['actions'] = {};
        
        // Add all the actions into the list to submit
        if (form) {
            jQuery.each(Jifty.Form.getActions(form), function(){
                named_args['actions'][this.moniker] = 1;
            });
        }
    }

    // SPA = Special code related to the Single Page Plugin

    // SPA Variable used to tell us to update __page under some conditions
    var optional_fragments;

    // SPA Update __page when the form calls a continuation
    if (form && form['J:CALL']) {
        optional_fragments = [ 
            prepare_element_for_update({
                'mode':   'Replace',
                'args':   {},
                'region': '__page',
                'path':   null
            }) 
        ];
    }

    // Build actions request structure
    var has_request = 0;
    var action_count = 0;
    request['actions'] = {};

    // Go through the monikers and actions we know about
    for (var moniker in named_args['actions']) {

        // SPA The extend moniker is special, skip it
        if (moniker == 'extend')
            continue;

        // Remember this action, we will disable it in a minute
        var disable = named_args['actions'][moniker];

        // Find the information related to this action
        var a = new Action(moniker, button_args);

        // Stuff this into the current actions map
        current_actions[moniker] = a;

        // SPA Special case for Redirect, allow optional, implicit __page
        // from the response to be used.
        if (a.actionClass == 'Jifty::Action::Redirect') {
            (function() {
                var fields = a.fields();
                var path = fields[fields.length - 1];
                optional_fragments = [ 
                    prepare_element_for_update({
                        'mode':   'Replace',
                        'args':   {},
                        'region': '__page',
                        'path':   path
                    }) 
                ];
            })()
        }

        // Fill these with empty values for the moment
        a.result = {};
        a.result.field_error = {};

        // Do we have an action registration field?
        if (a.register) {

            // Do we need to worry about a file upload field? If so, we cannot
            // ajax this, do a full form submission.
            //
            // TODO Consider some IFRAME magic to fallback upon?
            if (a.hasUpload()) {

                // XXX: restore default behavior in IE (and Opera, Safari)
                if(window.event) {
                    window.event.returnValue = true;
                }

                return true;
            }

            // Disable the action being submitted
            if(disable) {
                a.disable_input_fields(disabled_elements);
            }

            // Build a list of parameters
            var param = a.data_structure();
            var fields = param.fields;
            var override = named_args['action_arguments'][param.moniker] || {};

            // Override the action fields with action_arguments
            for (var argname in override) {
                if (fields[argname]) {
                    fields[argname].value = override[argname];
                }
                else {
                    fields[argname] = { value: override[argname] };
                }
            }

            // Add the parameters to the request we're building
            request['actions'][moniker] = param;
            ++action_count;

            // Remember that we have a request if we're submitting an action
            ++has_request;
        }
    }

    // Get ready to specify the fragment updates we're looking for
    request.fragments = {};

    var hooks = jQuery.map(Jifty.Update.handler_hooks, function(hook) { return hook.init() });

    // Build the fragments request
    for (var i = 0; i < named_args['fragments'].length; i++) {

        // Grab the current fragment
        var f = named_args['fragments'][i];

        // Put together the data structure that will request the fragment
        f = prepare_element_for_update(f);

        // Skip it if we just deleted the fragment
        if (!f) continue;

        var handled = 0;
        for (var j = 0; j < hooks.length; ++j) {
            if (hooks[j].process_fragment(f)) {
                handled = 1;
                break;
            }
        }
        if (handled)
            continue;

        // Build a fragment request from the path and args
        var name = f['region'];
        var fragment_request = fragments[ name ].data_structure(
            f['path'], f['args']
        );

        // Ask for the wrapper if we are making a new region
        if (f['is_new']) {
            fragment_request['wrapper'] = 1;
        }

        // Is the fragment in a form? Prevent <form></form> tags
        if (fragments[name].in_form) {
            fragment_request['in_form'] = 1;
        }

        // Push it onto the request stack
        request.fragments[name] = fragment_request;

        // Remember that we have a request if we're updating a fragment
        ++has_request;
    }

    jQuery.each(hooks, function() { this.process_update() } );

    if (!has_request) {
        return false;
    }

    // And when we get the result back, we'll want to deal with it
    //
    // NOTE: Success here doesn't mean the server liked the request, but that
    // the HTTP communication succeeded. There still might be errors validating
    // fields, with the app connecting to the database, etc.
    var onSuccess = function(responseXML) {
        if (named_args['preload']) {
            // Did we click on a region we were waiting for? If so, pretend
            // we're not preloading at all and treat this as a regular region
            // load.
            if (Jifty.want_preloaded_regions[ named_args['preload_key'] ]) {
                delete Jifty.want_preloaded_regions[ named_args['preload_key'] ];
            }
            // Otherwise, stash this preloaded region away where we can find it
            // for later (possible) reuse.
            else {
                Jifty.preloaded_regions[ named_args['preload_key'] ] = responseXML;
                return;
            }
        }

        // Grab the XML response
        var response = responseXML.documentElement;

        /* var response is an xml , which's content is like:
        <response>
            <fragment id="__page-region-name">
                <argument name="argument1">value1</argument>
                <argument name="argument2">value2</argument>
                <content> 
                        ...
                </content>
            </fragment>
            <result class="MyApp::Action::DoPost" moniker="do-post">
                <success>1</success>
                <content>
                    <title>Title</title>
                    <id>123</id>
                </content>
            </result>
        </response>
        */

        // Look through the action results looking for field validation errors
        walk_node(response, { 
            result: function(result) {
                var moniker = result.getAttribute("moniker");
                walk_node(result, { 
                    field: function(field) {
                        var error = field.getElementsByTagName('error')[0];

                        // Record the validation errors and such with the form
                        if (error) {
                            var text 
                                = error.textContent ? error.textContent
                                : (error.firstChild ? error.firstChild.nodeValue 
                                :                     '');
                            var action = current_actions[moniker];
                            action.result.field_error[field.getAttribute("name")] = text;
                        }
                    }
                });
            }
        });

        // Re-enable all the controls in the actions we previously disabled
        for ( var i = 0; i < disabled_elements.length; i++ ) {
            disabled_elements[i].disabled = false;
        }

        // empty known action. 
        // XXX: we should only need to discard actions being submitted

        // SPA We only care about __page sometimes
        var expected_fragments = optional_fragments ? optional_fragments 
                               :                      named_args['fragments'];

        // Loop through the response looking for fragments we requested
        for (var response_fragment = response.firstChild;
                response_fragment != null && 
                    response_fragment.nodeName == 'fragment';
                response_fragment = response_fragment.nextSibling) {

            // Get the returned ID attached to the new fragment for validation
            var exp_id = response_fragment.getAttribute("id");

            // Pull out the expected fragment from args matching the response
            var f;
            jQuery.each(expected_fragments, function() {
                if (exp_id == this['region']) {
                    f = this;
                    return false;
                }
            });

            // If we didn't expect it, skip it
            if (!f) {
                continue;
            }


            // Apply the fragment update to the page
            try {
                apply_fragment_updates(response_fragment, f);
            } catch (e) { alert(e) }

            // f
            jQuery.each(Jifty.Update.response_hooks, function(i) { 
                    this(response_fragment, f);
            });

            jQuery('.fragment_updates_attached').trigger('fragment_updates',f);
        }


        jQuery.each(hooks, function() { this.process_update() } );


        // Look through the response again
        walk_node(response, { 

            // Report all the action results we have
            result: function(result) {
                for (var key = result.firstChild;
                        key != null;
                        key = key.nextSibling) {
                    show_action_result(result.getAttribute("moniker"),key);
                }
            },

            // If we've been told to redirect, do it
            redirect: function(redirect) {
                document.location =  redirect.firstChild.firstChild.nodeValue;
            }
        });

        // Forget the actions, we're oh-fficially done with them
        current_actions = {}
    };

    // When an HTTP communication failure happens, we need to clean up
    var onFailure = function(transport, object) {

        // We failed, but we at least know we're done waiting
        if (!hide_wait) {
            hide_wait_message_now();
        }

        // Cry like a baby
        // Don't irritate the user about preload failures, maybe it'll work
        // if they actually do click through to the region
        if (!named_args['preload']) {
            alert("Unable to connect to server.\n\nTry again in a few minutes.");
        }

        // Record the failed request (XXX for debugging?)
        Jifty.failedRequest = transport;

        // Re-enable the forms, no sense in locking them up
        for ( var i = 0; i < disabled_elements.length; i++ ) {
            disabled_elements[i].disabled = false;
        }
    };

    // Almost ready to submit! Add the region arguments
    request.variables = {};
    jQuery.each(current_args, function(k, v) {
        request.variables['region-'+k] = v;
    });

    // Add in the continuation information
    request.continuation = named_args['continuation'];

    // Update the region state information or add it, if needed
    for (var i = 0; i < document.forms.length; i++) {
        var form = document.forms[i];

        jQuery.each(current_args, function(k, v) {
            if (form['J:V-region-'+k]) {
                form['J:V-region-'+k].value = v;
            } else {
                var hidden = document.createElement('input');
                hidden.setAttribute('type',  'hidden');
                hidden.setAttribute('name',  'J:V-region-'+k);
                hidden.setAttribute('id',    'J:V-region-'+k);
                hidden.setAttribute('value', v);
                form.appendChild(hidden);
            }
        })
    }

    var submitActions = function () {
        // If we have to submit actions, then it gets more complicated
        // We submit a request with the action and block preloading until
        // the action has returned
        if (action_count > 0) {

            // We do not want any region updates. That is for the preloading
            // request.
            delete request.fragments;

            Jifty.preload_action_request();
            jQuery.ajax({
                url:         document.URL,
                type:        'post',
                dataType:    'xml',
                data:        JSON.stringify(request),
                contentType: 'text/x-json',
                error:       onFailure,
                success:     onSuccess,
                complete:    Jifty.preload_action_respond
            });
        }
    };

    // Are we requesting a region we have preloaded? If so, use the response
    // from the cache instead of making a new request. Snappy!
    if (Jifty.preloaded_regions[ named_args['preload_key'] ]) {
        var faux_response = Jifty.preloaded_regions[ named_args['preload_key'] ];
        delete Jifty.preloaded_regions[ named_args['preload_key'] ];

        submitActions();

        onSuccess(faux_response);
        return false;
    }

    // If we're loading a region, then we should just wait for it instead
    // of making a second request and throwing away the preload. If the
    // onSuccess callback sees the want_preloaded_region it will immediately
    // process it.
    if (Jifty.preloading_regions[ named_args['preload_key'] ]) {
        Jifty.want_preloaded_regions[ named_args['preload_key'] ] = 1;
        submitActions();
        return false;
    }

    // Show the "Loading..." message (or equivalent)
    var hide_wait = named_args['hide_wait_message'];
    if (!hide_wait) {
        show_wait_message();
    }

    // Submit ajax request as JSON; expect XML in return
    jQuery.ajax({
        url:         document.URL,
        type:        'post',
        dataType:    'xml',
        data:        JSON.stringify(request),
        contentType: 'text/x-json',
        error:       onFailure,
        success:     onSuccess,

        // Hide the wait message when we're done
        complete: function() {
            // If we want this same region again, don't reuse it from the cache
            delete Jifty.preloading_regions[ named_args['preload_key'] ];

            if (!hide_wait) {
                hide_wait_message();
            }
        },

        beforeSend: function (request) {
            var headers = named_args['headers'];
            for (header in headers) {
                if (headers.hasOwnProperty(header)) {
                    request.setRequestHeader(header, headers[header]);
                }
            }
        }
    });

    // Disable regular browser form submission (we're Ajaxing instead)
    return false;
}

// A cache of preload_key to XMLresponse objects
Jifty.preloaded_regions = {};

// Are we currently preloading a given preload_key?
Jifty.preloading_regions = {};

// Are we submitting an action? If so, delay preloading.
Jifty.preloading_is_queued = 0;

// A cache of preloads to execute once we have a response to the action
// we submitted
Jifty.queued_preloads = [];

// For when we want a preloading region to be processed immediately (e.g. when
// we click a preloaded button)
Jifty.want_preloaded_regions = {};

Jifty.preload = function (args, trigger) {
    // XXX: prevent default behavior in IE
    if(window.event) {
        window.event.returnValue = false;
    }

    // Don't request the same region multiple times
    if (Jifty.preloading_regions[ args['preload_key'] ]) {
        return false;
    }

    // We're waiting for an action. We don't want to preload any more regions
    // until we know that action has been executed.
    if (Jifty.preloading_is_queued) {
        Jifty.preloading_regions[ args['preload_key'] ] = 1;
        Jifty.queued_preloads.push(function () {
            delete Jifty.preloading_regions[ args['preload_key'] ];
            Jifty.preload(args, trigger);
        });
        return false;
    }

    // Preloading is supposed to be silent
    args.hide_wait_message = 1;

    // Tell Jifty.update to delay processing of the response
    args.preload = 1;

    // Preloading should never submit actions, preloaded regions should be
    // relatively pure
    args.actions = [];

    Jifty.update(args, trigger);

    Jifty.preloading_regions[ args['preload_key'] ] = 1;

    return false;
}

Jifty.preload_action_request = function () {
    ++Jifty.preloading_is_queued;
};

Jifty.preload_action_respond = function () {
    if (--Jifty.preloading_is_queued == 0) {
        var preloads = Jifty.queued_preloads;
        Jifty.queued_preloads = [];

        for (var i = 0; i < preloads.length; ++i) {
            preloads[i]();
        }
    }
};

function update ( named_args, trigger ) {
    alert( 'please use Jifty.update instead of update.' );
    return Jifty.update( named_args, trigger );
}

function trace( msg ){
  if( typeof( jsTrace ) != 'undefined' ){
    jsTrace.send( msg );
  }
}


function show_wait_message (){
    jQuery('#jifty-wait-message').fadeIn(500);
}

function hide_wait_message (){
    jQuery('#jifty-wait-message').fadeOut(200);
}

function hide_wait_message_now() {
    jQuery('#jifty-wait-message').hide();
}

function show_action_result() {
    var moniker = arguments[0];
    var result = arguments[1];
    var status = result.nodeName;

    if (status == 'field') {
        // If this is a field, it has kids which are <error> or <message> -- loop through them
        for (var key = result.firstChild;
             key != null;
             key = key.nextSibling) {
            show_action_result(moniker,key);
        }
        return;
    }

    /* This is a workaround for Safari, which does not support textContent */
    var text = result.textContent
                    ? result.textContent
                    : (result.firstChild ? result.firstChild.nodeValue : '');

    if(status != 'message' && status != 'error') return;

    jQuery.jGrowl( text, {
        theme: 'result-'+status
    });
}

Jifty.Autocompleter = function() {
    var that = this;
    var args = arguments;
    jQuery(function () { that.initialize.apply(that, args) } );
    return this;
};

jQuery.extend(Jifty.Autocompleter.prototype, {
    initialize: function(field, div) {
        this.field  = Jifty.$(field);
        this.action = Jifty.Form.Element.getAction(this.field);
        this.url    = '/__jifty/autocomplete.xml';

        var sel = '#'+this.field.id+'-autocomplete';
        var autocomplete_div = jQuery(sel.replace(/:/g, '\\\\\\:'));
        var self = this;
        jQuery(this.field).focus(function(event) {
            self.changed  = true;
            self.hasFocus = true;
            Jifty.current_autocompleter_object = self;
            autocomplete_div.append(jQuery('#autocompleteHelper'))
            .show();
        })
        .blur(function() { autocomplete_div.hide() });
        
        jQuery(this.field).Autocomplete({
            source: this.url,
            minchars: -1,
            delay: 100,
            helperClass: 'autocomplete',
            selectClass: 'selected'
        });
    },

    beforeShow: function() {
        /* Prevents the race for canonicalization and updating via autocomplete */
        if ( this.field.onblur ) {
            this.element._onblur = this.element.onblur;
            this.element.onblur  = null;
        }
    },

    beforeHide: function() {
        /* Restore onblur and config option */
        if ( this.element._onblur ) {
            this.element.onblur  = this.element._onblur;
            this.element._onblur = null;
        }
    },

    afterUpdate: function(field, selection) {
        Jifty.Form.Element.validate(field);
    },

    buildRequest: function() {
        var request = { path: this.url, actions: {} };
        var a = {};
        a['moniker'] = 'autocomplete';
        a['class']   = 'Jifty::Action::Autocomplete';
        a['fields']  = {};
        a['fields']['moniker']  = this.action.moniker;
        a['fields']['argument'] = Jifty.Form.Element.getField(this.field);
        request['actions']['autocomplete'] = a;
        request['actions'][this.action.moniker] = this.action.data_structure();
        request['actions'][this.action.moniker]['active']  = 0;
        return request;
    }
});


Jifty.Placeholder = function() {
    this.initialize.apply(this, arguments);
    return this;
};

jQuery.extend(Jifty.Placeholder.prototype, {
  element: null,
  text: null,

  initialize: function(element, text) {
     this.element = Jifty.$(element);
     this.text = text;
     this.element.placeholderText = this.text;

     var self = this;

     jQuery( this.element )
     .bind("focus", function(event) {
         self.onFocus();
     })
     .bind("blur", function(event) {
         self.onBlur();
     });

     this.onBlur();

     var form = Jifty.Form.Element.getForm(element);

     if(form && !form.hasPlaceholders) {
         form.hasPlaceholders = true;
         // We can't attach this event via DOM event methods because
         // we need to call form.submit() sometimes and still have a good
         // way to call this event handler
         form.onsubmit = function () { Jifty.Form.clearPlaceholders(form); };
     }
  },

  onBlur: function() {
     /* On browser back/forward, the placeholder text will be remembered
        for the field, so we want to add the class if the value is the same
        as the placeholder text.  This does have the effect of making it
        impossible to submit a field with the same value as the placeholder. */
     if (this.element.value == '' || this.element.value == this.text) {
         jQuery(this.element).addClass('placeholder').val(this.text);
     }
  },

  onFocus: function() {
     Jifty.Placeholder.clearPlaceholder(this.element);
  }

});

jQuery.extend(Jifty.Placeholder, {
   hasPlaceholder: function(elt) {
       return jQuery(elt).hasClass('placeholder');
  },

  clearPlaceholder: function(elt) {
     // If the element's text isn't the same as its placeholder text, then the
     // browser screwed up and didn't clear our placeholder. Opera on Mac with
     // VirtueDesktops does this some times, and I lose data.
     // These are normalized because sometimes one has \r\n and the other has \n
     if (Jifty.Placeholder.hasPlaceholder(elt)) {
        elt.value = elt.value.replace(/\r/g, '');
        elt.placeholderText = elt.placeholderText.replace(/\r/g, '');
        if (elt.value == elt.placeholderText)
            jQuery(elt).removeClass('placeholder').val('');
     }
  }

});


// Define hasOwnProperty for Safari
if( !Object.prototype.hasOwnProperty ) {
    Object.prototype.hasOwnProperty = function( property ) {
        try {
            var prototype = this.constructor.prototype;
            while( prototype ) {
                if( prototype[ property ] == this[ property ] ) {
                    return false;
                }
                prototype = prototype.prototype;
            }
        } catch( e ) {}
        return true;
    }
}

/*
 * Jifty.Effect Usage:
 * 
 * Jifty.Effect(element, "Fade", { duration: 2.0 });
 * 
 * When called, instantly pefrom a js effect on give element.
 *
 * The last arg "option" is a hash. Currently it's only used for
 * specificing callbacks. There are two possible callbacks, before
 * and after. You may specify them like this:
 * 
 * Jifty.Effect(element, "Fade", { duration: 2.0 }, {
 *     before: function() { ... },
 *     after: function() { ... }
 * });
 *
 * The "before" callback is called right before the effect starts.
 * The "after" callback is called right after it's started, but not
 * necessarily ended.
 *
 * This function is written to make it possible that a Jifty plugin
 * can override default effects with other fancy javascript
 * libraries. By default, it delegates all the real work to
 * jQuery's built-in effect functions.
 *
 */

Jifty.Effect = function(el, name, args, options) {
    // Scriptaculous. TODO: This should be overrided by Jifty::Prototype plugins instead of coded in here.
    if (typeof Effect != 'undefined') {
        try {
            var effect = eval('Effect.' + name);
            var effect_args  = args || {};
            if (effect) {
                (effect)(el, effect_args);
            }
            return effect;
        } catch ( e ) {}
    }

    if (options == null) options = {};
    // jQuery built-ins
    var effect =
        name == 'Fade' ? 'fadeOut' :
        name == 'Appear' ? 'fadeIn' :
        name == 'SlideDown' ? 'slideDown' :
        name == 'SlideUp' ? 'slideUp' :
        name;

    if ( jQuery.isFunction( jQuery(el)[ effect ] ) ) {
        if ( jQuery.isFunction(options["before"]) ) 
            options["before"].call( el );

        ( jQuery(el)[ effect ] )(args);

        if ( jQuery.isFunction(options["after"]) ) 
            options["after"].call( el );
    }
};

/*
 * Provide an alias in Global namespace for backward compatibility.
 * Also Jifty.Form will still work even if prototype.js is loaded
 * after jifty.js.
 */

Form = {};

jQuery.extend(Form, {
    // Return an Array of Actions that are in this form
    getActions: function (element) {
        // DEPRECATED: use Jifty.Form.getActions instead
        return Jifty.Form.getActions(element);
    },
    clearPlaceholders: function(element) {
        // DEPRECATED: use Jifty.Form.clearPlaceholders instead
        return Jifty.Form.clearPlaceholders(element);
    },

    Element: {}
});

jQuery.extend(Form.Element, {
    // Get the moniker for this form element
    // Takes an element or an element id
    getMoniker: function (element) {
        // DEPRECATED: use Jifty.Form.Element.getMoniker instead
        return Jifty.Form.Element.getMoniker(element);
    },

    // Get the Action for this form element
    // Takes an element or an element id
    getAction: function (element) {
        // DEPRECATED: use Jifty.Form.Element.getAction instead
        return Jifty.Form.Element.getAction(element);
    },

    // Returns the name of the field
    getField: function (element) {
        // DEPRECATED: use Jifty.Form.Element.getField instead
        return Jifty.Form.Element.getField(element);
    },

    // The type of Jifty form element
    getType: function (element) {
        // DEPRECATED: use Jifty.Form.Element.getType instead
        return Jifty.Form.Element.getType(element);
    },

    // Validates the action this form element is part of
    validate: function (element) {
        // DEPRECATED: use Jifty.Form.Element.validate instead
        return Jifty.Form.Element.validate(element);
    },

    // Temporarily disable validation
            disableValidation: function(element) {
                // DEPRECATED: use Jifty.Form.Element.disableValidation instead
                return Jifty.Form.Element.disableValidation(element);
        },

            //Reenable validation            
            enableValidation: function(element) {
                // DEPRECATED: use Jifty.Form.Element.enableValidation instead
                return Jifty.Form.Element.enableValidation(element);
        },


    // Look up the form that this element is part of -- this is sometimes
    // more complicated than you'd think because the form may not exist
    // anymore, or the element may have been inserted into a new form.
    // Hence, we may need to walk the DOM.
    getForm: function (element) {
        // DEPRECATED: use Jifty.Form.Element.getForm instead
        return Jifty.Form.Element.getForm(element);
    },

    buttonArguments: function(element) {
        // DEPRECATED: use Jifty.Form.Element.buttonArguments instead
        return Jifty.Form.Element.buttonArguments(element);
    },

    buttonActions: function(element) {
        // DEPRECATED: use Jifty.Form.Element.buttonActions instead
        return Jifty.Form.Element.buttonActions(element);
    },  

    buttonFormElements: function(element) {
        // DEPRECATED: use Jifty.Form.Element.buttonFormElements instead
        return Jifty.Form.Element.buttonFormElements(element);
    },

    /* Someday Jifty may have the concept of "default"
       buttons.  For now, this clicks the first button that will
       submit the action associated with the form element.
     */
    clickDefaultButton: function(element) {
        // DEPRECATED: use Jifty.Form.Element.clickDefaultButton instead
        return Jifty.Form.Element.clickDefaultButton(element);
    },

    handleEnter: function(event) {
        // DEPRECATED: use Jifty.Form.Element.handleEnter instead
        return Jifty.Form.Element.handleEnter(event);
    }

});
