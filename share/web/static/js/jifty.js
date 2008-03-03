/* An empty class so we can create things inside it */
var Jifty = Class.create();

Jifty.Web = Class.create();
Jifty.Web.current_actions = new Array;
Jifty.Web.new_action = function() {
    var args = _get_named_args(arguments);
    var a;
    Jifty.Web.current_actions.each(function(x) { if (x.moniker == args.moniker) a = x });
    if (!a) throw "hate";
    
    return a;
};

Jifty.web = function() { return Jifty.Web };

function _get_named_args(args) {
    var result = {};
    for (var i = 0; i < args.length; i+=2) {
        result[args[i]] = args[i+1];
    }
    return result;

}

function _get_onclick(action_hash, name, args, path) {
    var onclick = 'if(event.ctrlKey||event.metaKey||event.altKey||event.shiftKey) return true; return Jifty.update('
    + JSON.stringify({'continuation': {},
                      'actions': action_hash,
                      'fragments': [{'mode': 'Replace', 'args': args, 'region': name, 'path': path}]})
    +', this)';
    onclick = onclick.replace(/"/g, "'"); //"' )# grr emacs!
        return onclick;
}
// XXX
var hyperlink  = function() {
    var args = _get_named_args(arguments);
    var current_region = Jifty.Web.current_region;
    var onclick = _get_onclick({}, current_region.name, current_region.args, args.onclick[0].replace_with);
    outs( a(function() { attr(function()
                              {return ['onclick', onclick, 'href', '#']});
            return args.label
                }));
}

var render_param = function(a, field) { outs(a.render_param(field)) };
var form_return  = function() {
    var args = _get_named_args(arguments);
    var action_hash = {};
    action_hash[args.submit.moniker] = 1;
    // XXX: fix the fabricated refresh-self
    // XXX: implicit onclick only for now

    // $self->_push_onclick($args, { refresh_self => 1, submit => $args->{submit} });
    // @args{qw/mode path region/} = ('Replace', Jifty->web->current_region->path, Jifty->web->current_region);

    var current_region = Jifty.Web.current_region;
    var onclick = _get_onclick(action_hash, current_region.name, current_region.args, current_region.path);
    outs(
         div(function() {
                 attr(function() { return ['class', 'submit_button'] });
                 return input(function() { attr(function()
                                                {return ['type', 'submit',
                                                         'onclick', onclick,
                                                         'class', 'widget button',
                                                         'id', 'S' + (++SERIAL + SERIAL_postfix),
                                                         'value', args.label,
                                                         'name', 'J:V-region-__page-signup_widget=_signup|J:ACTIONS=signupnow'] })});
                     }));

};

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

function apply_cached_for_action(code, actions) {
    Jifty.Web.current_actions = actions;
    this['out_buf'] = '';
    this['outs'] = function(text) { this.out_buf += text };
    actions.each(register_action);
    var foo = code();
    return foo;
    alert(foo);
    throw 'not yet';
}

/* Actions */
var Action = Class.create();
Action.prototype = {
    // New takes the moniker (a string), and an optional array of form
    // elements to additionally take into consideration
    initialize: function(moniker) {
        this.moniker = moniker;

        // Extra form parameters
        this.extras = $A();
        if (arguments.length > 1) {
            this.extras = arguments[1];
        }

        this.register = $('J:A-' + this.moniker);  // Simple case -- no ordering information
        if (! this.register) {
            // We need to go looking -- this also goes looking through this.extras, from above
            var elements = $A(document.getElementsByTagName('input'));
            for (var i = 0; i < this.extras.length; i++)
                elements.push(this.extras[i]);
            for (var i = 0; i < elements.length; i++) {
                if ((Form.Element.getMoniker(elements[i]) == this.moniker)
                 && (Form.Element.getType(elements[i]) == "registration")) {
                    this.register = elements[i];
                    break;
                }
            }
        }

        if (this.register) {
            this.form = Form.Element.getForm(this.register);
            this.actionClass = this.register.value;
        }
    },

    // Returns an Array of all fields in this Action
    fields: function() {
        if(!this.cached_fields) {
            var elements = new Array;
            var possible = Form.getElements(this.form);
            // Also pull from extra query parameters
            for (var i = 0; i < this.extras.length; i++)
                possible.push(this.extras[i]);

            for (var i = 0; i < possible.length; i++) {
                if (Form.Element.getMoniker(possible[i]) == this.moniker)
                    elements.push(possible[i]);
            }
            this.cached_fields = elements;
        }
        return this.cached_fields;
    },

    buttons: function() {
        var elements = new Array();
        var possible = Form.getElements(this.form);
        for(var i = 0; i < possible.length; i++) {
            if(possible[i].nodeName == 'INPUT' && possible[i].getAttribute("type") == 'submit') {
                actions = Form.Element.buttonActions(possible[i]);
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
            if (Form.Element.getField(elements[i]) == name)
                return elements[i];
        }
        return null;
    },

    // Serialize and return all fields needed for this action
    serialize: function() {
        var fields = this.fields();
        var serialized = new Array;

        for (var i = 0; i < fields.length; i++) {
            serialized.push(Form.Element.serialize(fields[i]));
        }
        return serialized.join('&');
    },

    // Returns true if there is a file upload form as one of our elements
    hasUpload: function() {
        var fields = this.fields();
        for (var i = 0; i < fields.length; i++) {
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

        a['fields']  = {};
        var fields = this.fields();
        for (var i = 0; i < fields.length; i++) {
            var f = fields[i];

            if (   (Form.Element.getType(f) != "registration")
                && (Form.Element.getValue(f) != null)
                && (!Jifty.Placeholder.hasPlaceholder(f)))
            {
                if (! a['fields'][Form.Element.getField(f)])
                    a['fields'][Form.Element.getField(f)] = {};
                var field = Form.Element.getField(f);
                var type = Form.Element.getType(f);

                // XXX: fallback value being an array makes server
                // upset, we don't think that should happen anyway
                if (type == 'fallback' && a['fields'][field][type])
                    continue                    
                a['fields'][field][type] = this._mergeValues(a['fields'][field][type],
                                                             Form.Element.getValue(f));
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

        new Ajax.Request(
            '/__jifty/validator.xml',  // Right now, the URL is actually completely irrelevant
            {
                asynchronous: 1,
                method: "get",
                parameters: this.serialize() + "&J:VALIDATE=1",
                onComplete:
                    function (request) {
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
                                            Element.show(err_div);
                                            err_div.innerHTML = field.firstChild.data;
                                        }
                                    } else if (field.nodeName == 'ok') {
                                        var err_div = document.getElementById(field.getAttribute("id"));
                                        if (err_div != null) {
                                            Element.hide(err_div);
                                            err_div.innerHTML = '';
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
                                            Element.show(note_div);
                                            note_div.innerHTML = field.firstChild.data;
                                        }
                                    }

                                    if (field.nodeName == 'update') {
                                        var field_name = field.getAttribute("name");
                                        for (var form_number = 0 ; form_number < document.forms.length; form_number++) {
                                            var form_field = document.forms[form_number].elements[field_name];
                                            if (form_field == null || !form_field.hasClassName('ajaxcanonicalization'))
                                                continue;
                                            form_field.value = field.firstChild.data;
                                        }
                                    }
                                }
                            }
                        }
                        return true;
                    }
            }
        ); 
        hide_wait_message();
        return false;
    },

    submit: function() {
        show_wait_message();
        new Ajax.Request(
            '/empty',
            { parameters: this.serialize() }
        );
        hide_wait_message();
    },

    disable_input_fields: function(disabled_elements) {
        var disable = function() {
            var elt = arguments[0];
            // Disabling hidden elements seems to  make IE sad for some reason
            if(elt.type != 'hidden') {
                // Triggers https://bugzilla.mozilla.org/show_bug.cgi?id=236791
                elt.blur();
                elt.disabled = true;
                disabled_elements.push(elt);
            }
        };
        this.fields().each(disable);
        this.buttons().each(disable);
    },

    enable_input_fields: function() {
        var enable = function() { arguments[0].disabled = false; };
        this.fields().each( enable );
        this.buttons().each( enable );
    },


    /* client side logic extracted from Jifty::Action */
    _action_spec: function() {
        if (!this.s_a) {
            /* XXX: make REST client accessible */
            var Todo = new AsynapseRecord('todo');
            this.s_a = $H(Todo.eval_ajax_get('/=/action/'+this.actionClass+'.js'));
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
ActionField = Class.create();
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
                            if (tthis.max_length) fields.push('size', tthis.max_length, 'maxlength', tthis.max_length);
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
Object.extend(Form, {
    // Return an Array of Actions that are in this form
    getActions: function (element) {
        var elements = new Array;
        var possible = Form.getElements(element);

        for (var i = 0; i < possible.length; i++) {
            if (Form.Element.getType(possible[i]) == "registration")
                elements.push(Form.Element.getAction(possible[i]));
        }
        
        return elements;
    },

    clearPlaceholders: function(element) {
        var elements = Form.getElements(element);
        for(var i = 0; i < elements.length; i++) {
            Jifty.Placeholder.clearPlaceholder(elements[i]);
        }
    }
});


var current_actions = $H();

/* Fields */
Object.extend(Form.Element, {
    // Get the moniker for this form element
    // Takes an element or an element id
    getMoniker: function (element) {
        element = $(element);    

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
        element = $(element);    
        var moniker = Form.Element.getMoniker(element);
        if (!current_actions.get(moniker))
            current_actions.set(moniker, new Action(moniker));
        return current_actions.get(moniker);
    },

    // Returns the name of the field
    getField: function (element) {
        element = $(element);    

        if (/^J:A(:F)+-[^-]+-.+$/.test(element.name)) {
            var bits = element.name.match(/^J:A(?::F)+-([^-]+)-.+$/);
            return bits[1];
        } else {
            return null;
        }
    },

    // The type of Jifty form element
    getType: function (element) {
        element = $(element);

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

    // Validates the action this form element is part of
    validate: function (element) {
            if(!Element.hasClassName(element, 'validation_disabled')) {
                Form.Element.getAction(element).validate();
            }
    },

    // Temporarily disable validation
            disableValidation: function(element) {
            Element.addClassName(element, 'validation_disabled');
        },

            //Reenable validation            
            enableValidation: function(element) {
            Element.removeClassName(element, 'validation_disabled');
        },


    // Look up the form that this element is part of -- this is sometimes
    // more complicated than you'd think because the form may not exist
    // anymore, or the element may have been inserted into a new form.
    // Hence, we may need to walk the DOM.
    getForm: function (element) {
        element = $(element);

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
        element = $(element);
        if (!element)
            return $H();

        if (((element.nodeName != 'INPUT') || (element.getAttribute("type") != "submit"))
         && ((element.nodeName != 'A')     || (! element.getAttribute("name"))))
            return $H();

        if (element.getAttribute("name").length == 0)
            return $H();

        var extras = $H();

        // Split other arguments out, if we're on a button
        var pairs = element.getAttribute("name").split("|");
        for (var i = 0; i < pairs.length; i++) {
            var bits = pairs[i].split('=',2);
            extras.set(bits[0], bits[1]);
        }
        return extras;
    },

    buttonActions: function(element) {
        element = $(element);
        var actions = Form.Element.buttonArguments(element).get('J:ACTIONS');
        if(actions) {
            return actions.split(",");
        } else {
            return new Array();
        }
    },  

    buttonFormElements: function(element) {
        element = $(element);

        var extras = $A();
        if (!element)
            return extras;

        var args = Form.Element.buttonArguments(element);
        var keys = args.keys();
        for (var i = 0; i < keys.length; i++) {
            var e = document.createElement("input");
            e.setAttribute("type", "hidden");
            e.setAttribute("name", keys[i]);
            e.setAttribute("value", args.get(keys[i]));
            e['virtualform'] = Form.Element.getForm(element);
            extras.push(e);
        }
        return extras;
    },

    /* Someday Jifty may have the concept of "default"
       buttons.  For now, this clicks the first button that will
       submit the action associated with the form element.
     */
    clickDefaultButton: function(element) {
        var action = Form.Element.getAction( element );
        if ( action ) {
            var buttons = action.buttons();
            for ( var i = 0; i < buttons.length; i++ ) {
                var b = buttons[i];
                if ( Form.Element.buttonActions( b ).indexOf( action.moniker ) >= 0 ) {
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
            if ( Form.Element.clickDefaultButton( event.target ) )
                event.preventDefault();
        }
    }

});

JSAN.use("DOM.Events");


// Form elements should focus if the CSS says so.
Behaviour.register( { ".focus": function(e) {
    /* Check to see if the element is already focused */
    if ( !Element.hasClassName(e, "focused") ) {
        e.focus();
        Element.addClassName(e, "focused");
    }
    } });


// Form elements should AJAX validate if the CSS says so
Behaviour.register({
    'input.ajaxvalidation, textarea.ajaxvalidation, input.ajaxcanonicalization, textarea.ajaxcanonicalization': function(elt) {
        DOM.Events.addListener(elt, "blur", function () {
                Form.Element.validate(elt);
            });
    },
    'input.date': function(e) {
        if ( !Element.hasClassName( e, 'has_calendar_link' ) ) {
            createCalendarLink(e);
            Element.addClassName( e, 'has_calendar_link' );
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
        if (   !Element.hasClassName( e, "jifty_enter_handler_attached" )
            && !Element.hasClassName( e, "ajaxautocompletes" ) )
        {
            /* Do not use keydown as the event, it will not work as expected in Safari */
            DOM.Events.addListener( e, "keypress", Form.Element.handleEnter );
            Element.addClassName( e, "jifty_enter_handler_attached" );
        }
    },
    ".messages": function(e) {
        if (   !Element.hasClassName( e, "jifty_enter_handler_attached" ) ) {
            e.innerHTML= 
              '<a  href="#" id="dismiss_'+e.id+'" title="Dismiss" onmousedown="this.onfocus=this.blur;" onmouseup="this.onfocus=window.clientInformation?null:window.undefined" onclick="Effect.Fade(this.parentNode); return false;">Dismiss</a>' + e.innerHTML;

            Element.addClassName( e, "jifty_enter_handler_attached" );
        }
    },
    '.form_field .error, .form_field .warning, .form_field .canonicalization_note': function(e) {
        if ( e.innerHTML == "" ) Element.hide(e);
    },
    '.jifty-region-lazy': function(e) {
        var region = e.getAttribute("id").replace(/^region-/,"");
        Jifty.update( { 'fragments': [{'region': region, 'mode': 'Replace'}]}, e);
    }
});


/* Regions */
// Keep track of the fragments on the page
var fragments = $H();
var Region = Class.create();
Region.prototype = {
    initialize: function(name, args, path, parent) {
        this.name = name;
        this.args = $H(args);
        this.path = path;
        this.parent = parent ? fragments.get(parent) : null;
        if (fragments.get(name)) {
            // If this fragment already existed, we want to wipe out
            // whatever evil lies we might have said earlier; do this
            // by clearing out everything that looks relevant
            var keys = current_args.keys();
            for (var i = 0; i < keys.length; i++) {
                var k = keys[i];
                var parsed = k.match(/^(.*?)\.(.*)/);
                if ((parsed != null) && (parsed.length == 3) && (parsed[1] == this.name)) {
                    current_args.unset(k);
                }
            }
        }

        fragments.set(name, this);
    },

    setPath: function(supplied) {
        // Merge in from current_args
        var keys = current_args.keys();
        for (var i = 0; i < keys.length; i++) {
            var k = keys[i];
            if (k == this.name) {
                this.path = current_args.get(k);
            }
        }

        // Update with supplied
        if (supplied != null) {
            this.path = supplied;
        }
        
        // Propagate back to current args
        current_args.set(this.name, this.path);

        // Return new value
        return this.path;
    },

    setArgs: function(supplied) {
        supplied = $H(supplied);
        // Merge in current args
        var keys = current_args.keys();
        for (var i = 0; i < keys.length; i++) {
            var k = keys[i];
            var parsed = k.match(/^(.*?)\.(.*)/);
            if ((parsed != null) && (parsed.length == 3) && (parsed[1] == this.name)) {
                this.args.set(parsed[2], current_args.get(k));
            }
        }

        // Merge in any supplied parameters
        this.args = this.args.merge(supplied);

        // Fill supplied parameters into current args
        keys = supplied.keys();
        for (var i = 0; i < keys.length; i++) {
            var k = keys[i];
            current_args.set(this.name+'.'+k, supplied.get(k));
        }
        
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
var current_args = $H();

// Prepare element for use in update()
//  - 'fragment' is a hash, see fragments in update()

function prepare_element_for_update(f) {
        var name = f['region'];

        // Find where we are going to go
        var element = $('region-' + f['region']);
        if (f['element']) {
            var possible = cssQuery(f['element']);
            if (possible.length == 0)
                element = null;
            else
                element = possible[0];
        }
        f['element'] = element;

        // If we can't find out where we're going, bail
        if (element == null)
            return;

        // If we're removing the element, do it now
        // XXX TODO: Effects on this?
        if (f['mode'] == "Delete") {
            fragments.set(name, null);
            Element.remove(element);
            return;
        }

        f['is_new'] = (fragments.get(name) ? false : true);
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
            new Region(name, f['args'], f['path'], f['parent']);
        } else if ((f['path'] != null) && f['toggle'] && (f['path'] == fragments.get(name).path)) {
            // If they set the 'toggle' flag, and clicking wouldn't change the path
            Element.update(element, '');
            fragments.get(name).path = null;
            return;
        } else if (f['path'] == null) {
            // If they didn't know the path, fill it in now
            f['path'] == fragments.get(name).path;
        }

    return f;    
}

var CACHE = {};


var walk_node = function(node, table) {
    for (var child = node.firstChild;
         child != null;
         child = child.nextSibling) {
        var name = child.nodeName.toLowerCase();
        if (table[name])
            table[name](child);
    }
}

var extract_cacheable = function(fragment, f) {
    walk_node(fragment,
    { cacheable: function(fragment_bit) {
            var c_type = fragment_bit.getAttribute("type");
            var textContent = '';
            if (fragment_bit.textContent) {
                textContent = fragment_bit.textContent;
            } else if (fragment_bit.firstChild) {
                textContent = fragment_bit.firstChild.nodeValue;
            } 
            try {
                var cache_func = eval(textContent);
                CACHE[f['path']] = { 'type': c_type, 'content': cache_func };
            }
            catch(e) { 
                alert(e);
                alert(textContent);
            }
        }
    });
};

// applying updates from a fragment
//   - fragment: the fragment from the server
//   - f: fragment spec
var apply_fragment_updates = function(fragment, f) {
    // We found the right fragment
    var dom_fragment = fragments.get(f['region']);
    var new_dom_args = $H();

    var element = f['element'];
    walk_node(fragment,
    { argument: function(fragment_bit) {
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
            new_dom_args.set(fragment_bit.getAttribute("name"), textContent);
        },
      content: function(fragment_bit) {
            var textContent = '';
            if (fragment_bit.textContent) {
                textContent = fragment_bit.textContent;
            } else if (fragment_bit.firstChild) {
                textContent = fragment_bit.firstChild.nodeValue;
            }
                    
            // Once we find it, do the insertion
            if (f['mode'] && (f['mode'] != 'Replace')) {
                var insertion = eval('Insertion.'+f['mode']);
                new insertion(element, textContent.stripScripts());
            } else {
                Element.update(element, textContent.stripScripts());
            }
            // We need to give the browser some "settle" time before
            // we eval scripts in the body
        YAHOO.util.Event.onAvailable(element.id, function() {
            (function() { this.evalScripts() }).bind(textContent)();
        });
        Behaviour.apply(element);
        }
    });
    dom_fragment.setArgs(new_dom_args);

    // Also, set us up the effect
    if (f['effect']) {
        try {
            var effect = eval('Effect.'+f['effect']);
            var effect_args  = f['effect_args'] || {};
            if (effect) {
                if (f['is_new'])
                    Element.hide($('region-'+f['region']));
                (effect)($('region-'+f['region']), effect_args);
            }
        } catch ( e ) {
            // Don't be sad if the effect doesn't exist
        }
    }
}

// Update a region.  Takes a hash of named parameters, including:
//  - 'actions' is an array of monikers to submit
//  - 'action_arguments' is a hash of action monikers to hashes of arguments which should override any arguments coming from form fields
//        the hash keys for 'action_arguments' are the values of the 'actions' array
//  - 'fragments' is an array of hashes, which may have:
//     - 'region' is the name of the region to update
//     - 'args' is a hash of arguments to override
//     - 'path' is the path of the fragment (if this is a new fragment)
//     - 'element' is the CSS selector of the element to update, if 'region' isn't supplied
//     - 'mode' is one of 'Replace', or the name of a Prototype Insertion
//     - 'effect' is the name of a Prototype Effect
Jifty.update = function () {
    // loads
    if(!Ajax.getTransport()) return true;
    // XXX: prevent default behavior in IE
    if(window.event) {
        window.event.returnValue = false;
    }

    var named_args = arguments[0];
    var trigger    = arguments[1];

    // The YAML/JSON data structure that will be sent
    var request = $H();

    // Keep track of disabled elements
    var disabled_elements = $A();

    // Set request base path
    request.set('path', '/__jifty/webservices/xml');

    // Grab extra arguments (from a button)
    var button_args = Form.Element.buttonFormElements(trigger);

    var form = Form.Element.getForm(trigger);
    // If the action is null, take all actions
    if (named_args['actions'] == null) {
        named_args['actions'] = {};
        // default to disable fields
        if (form)
            Form.getActions(form).map(function(x){
                named_args['actions'][x.moniker] = 1;
            });
    }
    var optional_fragments;
    if (form && form['J:CALL']) 
        optional_fragments = [ prepare_element_for_update({'mode':'Replace','args':{},'region':'__page','path': null}) ];
    // Build actions structure
    var has_request = 0;
    request.set('actions', $H());
    for (var moniker in named_args['actions']) {
        if (moniker == 'extend')
            continue;
        var disable = named_args['actions'][moniker];
        var a = new Action(moniker, button_args);
            current_actions.set(moniker, a); // XXX: how do i make this bloody singleton?
        // Special case for Redirect, allow optional, implicit __page
        // from the response to be used.
        if (a.actionClass == 'Jifty::Action::Redirect')
            optional_fragments = [ prepare_element_for_update({'mode':'Replace','args':{},'region':'__page','path': a.fields().last().value}) ];
        a.result = {}; a.result.field_error = {};
        if (a.register) {
            if (a.hasUpload())
                return true;
            if(disable) {
                a.disable_input_fields(disabled_elements);
            }
            var param = a.data_structure();
            var fields = param.fields;
            var override = named_args['action_arguments'][param.moniker] || {};
            for (var argname in override) {
                if (fields[argname]) {
                    fields[argname].value = override[argname];
                }
                else {
                    fields[argname] = { value: override[argname] };
                }
            }
            request.get('actions').set(moniker, param);
            ++has_request;
        }

    }

    request.set('fragments', $H());
    var update_from_cache = new Array;

    // Build fragments structure
    for (var i = 0; i < named_args['fragments'].length; i++) {
        var f = named_args['fragments'][i];
        f = prepare_element_for_update(f);
        if (!f) continue;

        var cached = CACHE[f['path']];
        if (cached && cached['type'] == 'static') {
            var my_fragment = document.createElement('fragment');
            var content_node = document.createElement('content');
            var cached_result;

            Jifty.Web.current_region = fragments.get(f['region']);
            try { cached_result = apply_cached_for_action(cached['content'], []) }
            catch (e) { alert(e) }

            content_node.textContent = cached_result;
            my_fragment.appendChild(content_node);
            my_fragment.setAttribute('id', f['region']);

            update_from_cache.push(function(){ apply_fragment_updates(my_fragment, f);
 } );
            continue;
        }
        else if (cached && cached['type'] == 'action') {
            var my_fragment = document.createElement('fragment');
            var content_node = document.createElement('content');

            my_fragment.appendChild(content_node);
            my_fragment.setAttribute('id', f['region']);
            update_from_cache.push(function(){
                    var cached_result;
                    Jifty.Web.current_region = fragments.get(f['region']);
                    try {
                        cached_result = apply_cached_for_action(cached['content'], Form.getActions(form));
                    }
                    catch (e) { alert(e); throw e }
                    content_node.textContent = cached_result;
                    apply_fragment_updates(my_fragment, f);
 } );
            continue;
        }
        else if (cached && cached['type'] == 'crudview') {
            try { // XXX: get model class etc as metadata in cache 
                // XXX: kill dup code
            var Todo = new AsynapseRecord('todo');
            var record = Todo.find(f['args']['id']);
            var my_fragment = document.createElement('fragment');
            var content_node = document.createElement('content');
            content_node.textContent = cached['content'](record);
            my_fragment.appendChild(content_node);
            my_fragment.setAttribute('id', f['region']);
            update_from_cache.push(function(){ apply_fragment_updates(my_fragment, f); } );
            } catch (e) { alert(e) };
            continue;
        }

        // Update with all new values
        var name = f['region'];
        var fragment_request = fragments.get(name).data_structure(f['path'], f['args']);

        if (f['is_new'])
            // Ask for the wrapper if we are making a new region
            fragment_request['wrapper'] = 1;

        // Push it onto the request stack
        request.get('fragments').set(name, fragment_request);
        ++has_request;
    }

    if (!has_request) {
        for (var i = 0; i < update_from_cache.length; i++)
            update_from_cache[i]();
        return false;
    }

    show_wait_message();

    // And when we get the result back..
    var onSuccess = function(transport, object) {
        // Grab the XML response
        var response = transport.responseXML.documentElement;

        // Get action results
        walk_node(response,
        { result: function(result) {
                var moniker = result.getAttribute("moniker");
                walk_node(result,
                          { field: function(field) {
                                  var error = field.getElementsByTagName('error')[0];
                                  if (error) {
                                      var text = error.textContent
                                          ? error.textContent
                                          : (error.firstChild ? error.firstChild.nodeValue : '');
                                      var action = current_actions.get(moniker);
                                      action.result.field_error[field.getAttribute("name")] = text;
                                      }
                              }});
            }});

        for ( var i = 0; i < disabled_elements.length; i++ ) {
            disabled_elements[i].disabled = false;
        }

        // empty known action. XXX: we should only need to discard actions being submitted

        // Loop through the result looking for it
        var expected_fragments = optional_fragments ? optional_fragments : named_args['fragments'];
        for (var response_fragment = response.firstChild;
             response_fragment != null && response_fragment.nodeName == 'fragment';
             response_fragment = response_fragment.nextSibling) {

            var exp_id = response_fragment.getAttribute("id");
            var f = expected_fragments.find(function(f) { return exp_id == f['region'] });
            if (!f)
                continue;

            try {
                apply_fragment_updates(response_fragment, f);
            }catch (e) { alert(e) }
            extract_cacheable(response_fragment, f);
        }

        update_from_cache.each(function(x) { x() });

        walk_node(response,
        { result: function(result) {
                for (var key = result.firstChild;
                     key != null;
                     key = key.nextSibling) {
                    show_action_result(result.getAttribute("moniker"),key);
                }
            },
          redirect: function(redirect) {
                document.location =  redirect.firstChild.firstChild.nodeValue;
        }});
        current_actions = $H();
    };
    var onFailure = function(transport, object) {
        hide_wait_message_now();

        alert("Unable to connect to server.\n\nTry again in a few minutes.");

        Jifty.failedRequest = transport;

        for ( var i = 0; i < disabled_elements.length; i++ ) {
            disabled_elements[i].disabled = false;
        }
    };

    // Build variable structure
    request.set('variables', $H());
    var keys = current_args.keys();
    for (var i = 0; i < keys.length; i++) {
        var k = keys[i];
        request.get('variables').set('region-'+k, current_args.get(k));
    }

    // Build continuation structure
    request.set('continuation', named_args['continuation']);

    // Push any state variables which we set into the forms
    for (var i = 0; i < document.forms.length; i++) {
        var form = document.forms[i];
        var keys = current_args.keys();
        for (var j = 0; j < keys.length; j++) {
            var n = keys[j];
            if (form['J:V-region-'+n]) {
                form['J:V-region-'+n].value = current_args.get(n);
            } else {
                var hidden = document.createElement('input');
                hidden.setAttribute('type',  'hidden');
                hidden.setAttribute('name',  'J:V-region-'+n);
                hidden.setAttribute('id',    'J:V-region-'+n);
                hidden.setAttribute('value', current_args.get(n));
                form.appendChild(hidden);
            }
        }
    }

    // Set up our options
    var options = { postBody: request.toJSON(), //JSON.stringify(request.toObject),
                    onSuccess: onSuccess,
                    onException: onFailure,
                    onFailure: onFailure,
                    onComplete: function(){hide_wait_message()},
                    requestHeaders: ['Content-Type', 'text/x-json']
    };

    // Go!
    new Ajax.Request(document.URL,
                     options
                    );
    return false;
}

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
    if ($('jifty-wait-message'))
        new Effect.Appear('jifty-wait-message', {duration: 0.5});
}

function hide_wait_message (){
    if ($('jifty-wait-message'))
        new Effect.Fade('jifty-wait-message', {duration: 0.2});
}

function hide_wait_message_now() {
    if ($('jifty-wait-message'))
        Element.hide('jifty-wait-message');
}

function show_action_result() {
    var popup = $('jifty-result-popup');
    if(!popup) return;

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

    var node = document.createElement('div');
    var node_id = 'result-' + moniker;
    node.setAttribute('id', node_id);
    node.className = "popup_notification result-" + status;
    node.innerHTML = text;
    
    var wrap1 = document.createElement("div");
    wrap1.className = "dropshadow_wrap1";
    var wrap2 = document.createElement("div");
    wrap2.className = "dropshadow_wrap2";
    var wrap3 = document.createElement("div");
    wrap3.className = "dropshadow_wrap3";

    wrap1.appendChild(wrap2);
    wrap2.appendChild(wrap3);
    wrap3.appendChild(node);
    
    if(popup.hasChildNodes()) {
        popup.insertBefore(wrap1, popup.firstChild);
    } else {
        popup.appendChild(wrap1);
    }
    
    setTimeout(function () {
           new Effect.Fade(wrap1, {duration: 3.0});
    }, 3500);
}

Jifty.Autocompleter = Class.create();
Object.extend(Object.extend(Jifty.Autocompleter.prototype, Ajax.Autocompleter.prototype), {
  initialize: function(field, div) {
    this.field  = $(field);
    this.action = Form.Element.getAction(this.field);
    this.url    = '/__jifty/autocomplete.xml';

    Event.observe(this.field, "focus", this.onFocus.bindAsEventListener(this));
    this.baseInitialize(this.field, $(div), {
        minChars: "0",
        beforeShow: this.beforeShow,
        beforeHide: this.beforeHide,
        frequency: 0.1,
        onShow: this.onShow,
        onHide: this.onHide,
        afterUpdateElement: this.afterUpdate
    });

    if ((document.all)&&(navigator.appVersion.indexOf("MSIE")!=-1)) {
        Event.observe(this.element, "keydown", this.onKeyPress.bindAsEventListener(this));
    }
  },

  onShow: function(element, update) {
      if(!update.style.position || update.style.position=='absolute') {
        update.style.position = 'absolute';
        Position.clone(element, update, {setHeight: false, offsetTop: element.offsetHeight});
      }
      Element.show( update );
  },

  onHide: function(element, update) {
      Element.hide( update );
  },

  beforeShow: function(obj) {
    /* Prevents the race for canonicalization and updating
       via autocomplete */
    if ( obj.element.onblur ) {
        obj.element._onblur = obj.element.onblur;
        obj.element.onblur  = null;
    }
  },

  beforeHide: function(obj) {
    /* Restore onblur and config option */
    if ( obj.element._onblur ) {
        obj.element.onblur  = obj.element._onblur;
        obj.element._onblur = null;
    }
  },

  onFocus: function(event) {
    this.changed  = true;
    this.hasFocus = true;

    if (this.observer)
        clearTimeout(this.observer);
    
    this.onObserverEvent();
  },

  afterUpdate: function(field, selection) {
     Form.Element.validate(field);
  },
  
  getUpdatedChoices: function() {
      var request = { path: this.url, actions: {} };

      var a = {}; //$H();
      a['moniker'] = 'autocomplete';
      a['class']   = 'Jifty::Action::Autocomplete';
      a['fields']  = {}; //$H();
      a['fields']['moniker']  = this.action.moniker;
      a['fields']['argument'] = Form.Element.getField(this.field);
      request['actions']['autocomplete'] = a;
      request['actions'][this.action.moniker] = this.action.data_structure();
      request['actions'][this.action.moniker]['active']  = 0;

      var options = { postBody: JSON.stringify(request),
                      onComplete: this.onComplete.bind(this),
                      requestHeaders: ['Content-Type', 'text/x-json']
      };

      new Ajax.Request(this.url,
                       options
                       );
  }


});

Jifty.Placeholder = Class.create();
Object.extend(Jifty.Placeholder.prototype, {
  element: null,
  text: null,

  initialize: function(element, text) {
     this.element = $(element);
     this.text = text;
     this.element.placeholderText = this.text;

     Event.observe(element, 'focus', this.onFocus.bind(this));
     Event.observe(element, 'blur', this.onBlur.bind(this));
     this.onBlur();

     var form = Form.Element.getForm(element);
     
     if(form && !form.hasPlaceholders) {
         form.hasPlaceholders = true;
         // We can't attach this event via DOM event methods because 
         // we need to call form.submit() sometimes and still have a good
         // way to call this event handler
         form.onsubmit = function () { Form.clearPlaceholders(form); };
     }
  },

  onBlur: function() {
     /* On browser back/forward, the placeholder text will be remembered
        for the field, so we want to add the class if the value is the same
        as the placeholder text.  This does have the effect of making it
        impossible to submit a field with the same value as the placeholder. */
     if (this.element.value == '' || this.element.value == this.text) {
       Element.addClassName(this.element, 'placeholder');
       this.element.value = this.text;
     }
  },

  onFocus: function() {
     Jifty.Placeholder.clearPlaceholder(this.element);
  }

});

Object.extend(Jifty.Placeholder, {

   hasPlaceholder: function(elt) {
     return Element.hasClassName(elt, 'placeholder');
  },
            
  clearPlaceholder: function(elt) {
     // If the element's text isn't the same as its placeholder text, then the
     // browser screwed up and didn't clear our placeholder. Opera on Mac with
     // VirtueDesktops does this some times, and I lose data.
     // These are normalized because sometimes one has \r\n and the other has \n
     elt.value = elt.value.replace(/\r/g, '');
     elt.placeholderText = elt.placeholderText.replace(/\r/g, '');

     if(Jifty.Placeholder.hasPlaceholder(elt) && elt.value == elt.placeholderText) {
       elt.value = '';
       Element.removeClassName(elt, 'placeholder');
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

function _sp_submit_form(elt, event, submit_to) {
    var form = Form.Element.getForm(elt);
    var elements = Form.getElements(form);

    // Three things need to get merged -- hidden defaults, defaults
    // from buttons, and form values.  Hence, we build up three lists
    // and then merge them.
    var hiddens = $H();
    var buttons = $H();
    var inputs = $H();
    for (var i = 0; i < elements.length; i++) {
        var e = elements[i];
        var parsed = e.getAttribute("name").match(/^J:V-region-__page\.(.*)/);
        var extras = Form.Element.buttonArguments(e);
        if (extras.keys().length > 1) {
            // Button with values
            for (var j = 0; j < extras.keys().length; j++) {
                if ( extras.keys()[j] == 'extend' ) continue;
                // Might also have J:V mappings on it
                parsed = extras.keys()[j].match(/^J:V-region-__page\.(.*)/);
                if ((parsed != null) && (parsed.length == 2)) {
                    buttons.set(parsed[1], extras.values()[j]);
                } else if (extras.keys()[j].length > 0) {
                    inputs.set(extras.keys()[j], extras.values()[j]);
                }
                
            }
        } else if ((parsed != null) && (parsed.length == 2)) {
            // Hidden default
            hiddens.set(parsed[1], $F(e));
        } else if (e.name.length > 0) {
            // Straight up values
            inputs.set(e.name, $F(e));
        }
    }

    var args = hiddens.merge(buttons.merge(inputs));

    /* we want to feed a common object instead of a Hash to Jifty.update */ 
    var args_object = {};
    args.each( function( pair ) { args_object[pair.key] = pair.value; } );

    if(event.ctrlKey||event.metaKey||event.altKey||event.shiftKey) return true;
    return Jifty.update( {'continuation':{},'actions':null,'fragments':[{'mode':'Replace','args':args_object,'region':'__page','path': submit_to}]}, elt );
}
