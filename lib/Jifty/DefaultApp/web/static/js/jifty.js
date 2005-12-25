/* An empty class so we can create things inside it */
var Jifty = Class.create();

/* General methods for dealing with forms, actions, and fields */
/* Actions */
var Action = Class.create();
Action.prototype = {
    // New takes the moniker, a string
    initialize: function(moniker) {
        this.moniker = moniker;

        this.register = $('J:A-' + this.moniker);  // Simple case -- no ordering information
        if (! this.register) {
            // We need to go looking
            var elements = document.getElementsByTagName('input');
            for (var i = 0; i < elements.length; i++) {
                if (Form.Element.getMoniker(elements[i]) == this.moniker) {
                    this.register = elements[i];
                    break;
                }
            }
        }

        this.form = Form.Element.getForm(this.register);
        this.actionClass = this.register.value;
    },

    // Returns an Array of all fields in this Action
    fields: function() {
        var elements = new Array;
        var possible = Form.getElements(this.form);

        for (var i = 0; i < possible.length; i++) {
            if (Form.Element.getMoniker(possible[i]) == this.moniker)
                elements.push(possible[i]);
        }
        return elements;
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

    // Validate the action
    validate: function() {
        show_wait_message();
        var id = this.register.id;

        new Ajax.Request(
            '/validator.xml',  // Right now, the URL is actually completely irrelevant
            {
                asynchronous: 1,
                method: "get",
                parameters: this.serialize() + "&J:VALIDATE=1",
                onComplete:
                    function (request) {
                        var response  = request.responseXML.documentElement;
                        for (var action = response.firstChild; action != null; action = action.nextSibling) {
                            if ((action.nodeName != 'action') || (action.getAttribute("id") != id))
                                continue;
                            for (var field = action.firstChild; field != null; field = field.nextSibling) {
                                // Possibilities for field.nodeName: it could be #text (whitespace),
                                // or 'blank' (the field was blank, don't mess with the error div), or 'ok'
                                // (clear the error div!) or 'error' (fill in the error div!)
                                if (field.nodeName == 'error') {
                                    var err_div = document.getElementById(field.getAttribute("id"));
                                    if (err_div != null) {
                                        err_div.innerHTML = field.firstChild.data;
                                    }
                                } else if (field.nodeName == 'ok') {
                                    var err_div = document.getElementById(field.getAttribute("id"));
                                    if (err_div != null) {
                                        err_div.innerHTML = '';
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
    }
};



/* Forms */
// Return an Array of Actions that are in this form
Form.getActions = function (element) {
    var elements = new Array;
    var possible = Form.getElements(element);

    for (var i = 0; i < possible.length; i++) {
        if (Form.Element.isRegistration(possible[i]))
            elements.push(new Action(Form.Element.getMoniker(possible[i])));
    }

    return elements;
};

/* Fields */
// Get the moniker for this form element
// Takes an element or an element id
Form.Element.getMoniker = function (element) {
     // if we have an element id, get the element itself
     if (typeof(element) == "string") {
         element = $(element);    
    }
    if (/^J:A:F(:F)*-[^-]+-.+$/.test(element.name)) {
        var bits = element.name.match(/^J:A:F(?::F)*-[^-]+-(.+)$/);
        return bits[1];
    } else if (/^J:A-(\d+-)?.+$/.test(element.name)) {
        var bits = element.name.match(/^J:A-(?:\d+-)?(.+)$/);
        return bits[1];
    } else {
        return null;
    }
};

// Get the Action for this form element
// Takes an element or an element id
Form.Element.getAction = function (element) {
        // if we have an element id, get the element itself
        if (typeof(element) == "string") {
            element = $(element);    
            }
    var moniker = Form.Element.getMoniker(element);
    return new Action(moniker);
}

// Returns true if this form element is the registration for its action
Form.Element.isRegistration = function (element) {
    return /^J:A-/.test(element.name)
};

// Validates the action this form element is part of
Form.Element.validate = function (element) {
    Form.Element.getAction(element).validate();
};

// Form elements should AJAX validate if the CSS says so
Behaviour.register({
    'input.ajaxvalidation': function(elt) {
        elt.onblur = function () {
            Form.Element.validate(this);
        } 
    }
});

// Look up the form that this element is part of -- this is sometimes
// more complicated than you'd think because the form may not exist
// anymore, or the element may have been inserted into a new form.
// Hence, we may need to walk the DOM.
Form.Element.getForm = function (element) {
    if (element.form)
        return element.form;

    for (var elt = element.parentNode; elt != null; elt = elt.parentNode) {
        if (elt.nodeName == 'FORM') {
            element.form = elt;
            return elt;
        }
    }
    return null;
}

function serialize(thing) {
    var serialized = new Array;
    for (n in thing) {
        if ((typeof(thing[n]) == "string"  && thing[n].length) || typeof(thing[n]) == "number")
            serialized.push(encodeURIComponent(n) + '=' + 
                            encodeURIComponent(thing[n]));
    }
    return serialized.join('&');
}

var fragments = {};
var current_args = {};
function region(name, args, path) {
    fragments[name] = {name: name, args: args, path: path};
    current_args[name] = {};
}

function update() {
    show_wait_message();
    arguments = arguments[0];

    var args = {};
    // Find the name of the region
    var name = arguments['region'];

    // Pull defaults from the region's definition, if it exists
    if (fragments[name]) {
        for (var n in fragments[name].args) {
            args[n] = fragments[name].args[n];
        }
    }

    // Pull in defaults from previous clicks to this region
    for (var n in current_args) {
        if (typeof(current_args[n]) == "string") {
            args[n] = current_args[n];
            var parsed = n.match(/J:NV-region-(.*?)\.(.*)/);

            // If this is a formalization of one of our arguments,
            // pull in the short form as well
            if ((parsed != null) && (parsed.length == 3) && (parsed[1] == name)) {
                args[parsed[2]] = current_args[n];
            }
        }
    }

    // Take the args we were passed, and push them into the defaults
    for (var n in arguments['args']) {
        args[n] = arguments['args'][n];
        if (n.indexOf('J:') != 0) {
            current_args['J:NV-region-'+name+'.'+n] = args[n];
            args['J:NV-region-'+name+'.'+n] = args[n];
        }
    }

    // Set up where the path is
    var path;
    if (arguments['path'] != null) {
        path = arguments['path'];
    } else if (fragments[name]) {
        path = fragments[name].path;
    } else {
        alert('no path!');
        return;
    } 
    args['J:NV-region-'+name] = path;
    current_args['J:NV-region-'+name] = path;

    // Push any state variables which we set into the forms
    for (var i = 0; i < document.forms.length; i++) {
        var form = document.forms[i];
        for (var n in args) {
            if ((typeof(args[n]) == "string") && (/^J:NV-/.test(n))) {
                if (form[n]) {
                    form[n].value = args[n];
                } else {
                    var hidden = document.createElement('input');
                    hidden.setAttribute('type',  'hidden');
                    hidden.setAttribute('name',  n);
                    hidden.setAttribute('id',    n);
                    hidden.setAttribute('value', args[n]);
                    form.appendChild(hidden);
                }
            }
        }
    }

    // Name and path
    args['J-NAME'] = name;
    args['J-PATH'] = document.URL;

    // Ask for the wrapper if we are making a new region
    if (! fragments[name]) {
        args['J-REGION'] = 1;
    }

    // Add any actions which need to get run
    var query = serialize(args);
    if (arguments['submit']) {
        for (var i = 0; i < arguments['submit'].length; i++) {
            var a = new Action(arguments['submit'][i]);
            query = query + '&' + a.serialize();
        }
    }

    // Find the element that is getting dealt with
    var element = $('region-' + name);
    if (arguments['element']) {
        var possible = document.getElementsBySelector(arguments['element']);
        if (possible.length == 0)
            alert('no possible elements');
        else
            element = possible[0];
    }

    // Set up our options
    var options = { parameters: query,
                    onComplete: function () { Behaviour.apply();
                                              hide_wait_message();
                                            },
                    evalScripts: true };

    // Change insertion mode if need be
    if (arguments['mode'] && (arguments['mode'] != 'Replace')) {
        options['insertion'] = eval('Insertion.'+arguments['mode']);
    }

    // Change the effect
    if (arguments['effect']) {
        var old = options['onComplete'];
        var effect = eval('Effect.'+arguments['effect']);
        var is_new = (fragments[name] == null) ? true : false;
        options['onComplete'] = function() {
            if (is_new) {
                Element.hide($('region-'+name));
            }
            (effect)($('region-'+name));
            old();
        };
    }

    // Go!
    new Ajax.Updater(element,
                     path,
                     options
                    );
}

function trace( msg ){
  if( typeof( jsTrace ) != 'undefined' ){
    jsTrace.send( msg );
  }
}


function show_wait_message (){
    new Effect.Appear('jifty-wait-message', {duration: 0.5});
}

function hide_wait_message (){
    new Effect.Fade('jifty-wait-message', {duration: 0.2});
}



Jifty.Autocompleter = Class.create();
Object.extend(Object.extend(Jifty.Autocompleter.prototype, Ajax.Autocompleter.prototype), {
  initialize: function(element, update, url, options) {
          this.baseInitialize(element, update, options);
    this.options.asynchronous  = true;
    this.options.onComplete    = this.onComplete.bind(this);
    this.options.defaultParams = this.options.parameters || null;
    this.url                   = url;
  },

  getUpdatedChoices: function() {
    entry = encodeURIComponent("J:A-autocomplete")
        + "=" +encodeURIComponent("Jifty::Action::Autocomplete");

    entry += '&' + encodeURIComponent("J:A:F-argument-autocomplete") 
        + "=" + encodeURIComponent(this.options.paramName);
      
    entry += '&' + encodeURIComponent("J:A:F-action-autocomplete") 
        + "=" + encodeURIComponent(
                        Form.Element.getMoniker(this.options.paramName)
                        );

    entry += '&'+ encodeURIComponent("J:ACTIONS") + '=' + encodeURIComponent("autocomplete");


    this.options.parameters = this.options.callback ?
      this.options.callback(this.element, entry) : entry;

    if(this.options.defaultParams)
      this.options.parameters += '&' + this.options.defaultParams;
      
    var action =  Form.Element.getAction(this.options.paramName);
      this.options.parameters += '&' + action.serialize();

    new Ajax.Request(this.url, this.options);
  }


});

