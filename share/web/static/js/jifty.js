/* An empty class so we can create things inside it */
var Jifty = Class.create();

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

    // Return the action as a data strcture suitible to be JSON'd
    data_structure: function() {
        var a = {};
        a['moniker'] = this.moniker;
        a['class']   = this.actionClass;

        a['fields']  = {};
        var fields = this.fields();
        for (var i = 0; i < fields.length; i++) {
            var f = fields[i];

            if ((Form.Element.getType(f) != "registration") && Form.Element.getValue(f)) {
                if (! a['fields'][Form.Element.getField(f)])
                    a['fields'][Form.Element.getField(f)] = {};
                a['fields'][Form.Element.getField(f)][Form.Element.getType(f)] = Form.Element.getValue(f);
            }
        }

        return a;
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
Object.extend(Form, {
    // Return an Array of Actions that are in this form
    getActions: function (element) {
        var elements = new Array;
        var possible = Form.getElements(element);

        for (var i = 0; i < possible.length; i++) {
            if (Form.Element.getType(possible[i]) == "registration")
                elements.push(new Action(Form.Element.getMoniker(possible[i])));
        }
        
        return elements;
    }
});



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
        return new Action(moniker);
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
        } else if (/^J:A:F:F:F-/.test(element.name)) {
            return "doublefallback";
        } else {
            return null;
        }
    },

    // Validates the action this form element is part of
    validate: function (element) {
        Form.Element.getAction(element).validate();
    },

    // Look up the form that this element is part of -- this is sometimes
    // more complicated than you'd think because the form may not exist
    // anymore, or the element may have been inserted into a new form.
    // Hence, we may need to walk the DOM.
    getForm: function (element) {
        element = $(element);

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
});

// Form elements should AJAX validate if the CSS says so
Behaviour.register({
    'input.ajaxvalidation': function(elt) {
        elt.onblur = function () {
            Form.Element.validate(this);
        } 
    }
});



/* Regions */
// Keep track of the fragments on the page
var fragments = $H();

var Region = Class.create();
Region.prototype = {
    initialize: function(name, args, path) {
        this.name = name;
        this.args = $H(args);
        this.path = path;
        if (fragments[name]) {
            // If this fragment already existed, we want to wipe out
            // whatever evil lies we might have said earlier; do this
            // by clearing out everything that looks relevant
            var keys = current_args.keys();
            for (var i = 0; i < keys.length; i++) {
                var k = keys[i];
                var parsed = k.match(/^(.*?)\.(.*)/);
                if ((parsed != null) && (parsed.length == 3) && (parsed[1] == this.name)) {
                    delete current_args[k];
                }
            }
        }

        fragments[name] = this;
    },

    setPath: function(supplied) {
        // Merge in from current_args
        var keys = current_args.keys();
        for (var i = 0; i < keys.length; i++) {
            var k = keys[i];
            if (k == this.name) {
                this.path = current_args[k];
            }
        }

        // Update with supplied
        if (supplied != null) {
            this.path = supplied;
        }
        
        // Propagate back to current args
        current_args[this.name] = this.path;

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
                this.args[parsed[2]] = current_args[k];
            }
        }

        // Merge in any supplied parameters
        this.args = this.args.merge(supplied);

        // Fill supplied parameters into current args
        keys = supplied.keys();
        for (var i = 0; i < keys.length; i++) {
            var k = keys[i];
            current_args[this.name+'.'+k] = supplied[k];
        }
        
        // Return new values
        return this.args;
    },

    data_structure: function(path, args) {
        return {
            name: this.name,
            path: this.setPath(path),
            args: this.setArgs(args),
        }
    }
};


// Keep track of the state variables.
var current_args = $H();

// Update a region.  Takes a hash of named parameters, including:
//  - 'actions' is an array of monikers to submit
//  - 'fragments' is an array of hashes, which may have:
//     - 'region' is the name of the region to update
//     - 'args' is a hash of arguments to override
//     - 'path' is the path of the fragment (if this is a new fragment)
//     - 'element' is the CSS selector of the element to update, if 'region' isn't supplied
//     - 'mode' is one of 'Replace', or the name of a Prototype Insertion
//     - 'effect' is the name of a Prototype Effect
function update() {
    show_wait_message();
    var named_args = arguments[0];

    // The YAML/JSON data structure that will be sent
    var request = $H();

    // Set request base path
    request['path'] = document.URL;

    // Build actions structure
    request['actions'] = {};
    for (var i = 0; i < named_args['actions'].length; i++) {
        var moniker = named_args['actions'][i];
        var a = new Action(moniker);
        if (a.register)
            request['actions'][moniker] = a.data_structure();
    }

    request['fragments'] = {};
    // Build fragments structure
    for (var i = 0; i < named_args['fragments'].length; i++) {
        var f = named_args['fragments'][i];

        var name = f['region'];
        f['is_new'] = (fragments[name] ? false : true);
        
        // If it's new, we need to create it so we can dump it
        if (f['is_new'])
            new Region(name, f['args'], f['path']);

        // Update with all new values
        var fragment_request = fragments[name].data_structure(f['path'], f['args']);

        // Ask for the wrapper if we are making a new region
        if (f['is_new'])
            fragment_request['wrapper'] = 1;

        // Push it onto the request stack
        request['fragments'][name] = fragment_request;
    }

    // And when we get the result back..
    var onComplete = function(transport, object) {
        // In case there's no XML in the response, or what have you
        try {
            // Grab the XML response
            var response = transport.responseXML.documentElement;

            // For each fragment we requested
            for (var i = 0; i < named_args['fragments'].length; i++) {
                var f = named_args['fragments'][i];

                // Find the element that is getting dealt with
                var element = $('region-' + f['region']);
                if (f['element']) {
                    var possible = document.getElementsBySelector(f['element']);
                    if (possible.length == 0)
                        element = null;
                    else
                        element = possible[0];
                }
                // Change insertion mode if need be
                var insertion = null;
                if (f['mode'] && (f['mode'] != 'Replace')) {
                    insertion = eval('Insertion.'+f['mode']);
                }

                // If we found something to replace
                if (element) {
                    // Loop through the result looking for it
                    for (var response_fragment = response.firstChild;
                         response_fragment != null;
                         response_fragment = response_fragment.nextSibling) {
                        if (response_fragment.getAttribute("id") == f['region']) {
                            // Once we find it, do the insertion
                            if (insertion) {
                                new insertion(element, response_fragment.textContent.stripScripts());
                            } else {
                                Element.update(element, response_fragment.textContent.stripScripts());
                            }
                            // We need to give the browser some "settle" time before we eval scripts in the body
                            setTimeout((function() { this.evalScripts() }).bind(response_fragment.textContent), 10);
                        }
                    }

                    // Also, set us up the effect
                    if (f['effect']) {
                        var effect = eval('Effect.'+f['effect']);
                        var effect_args  = f['effect_args'] || {};
                        if (f['is_new'])
                            Element.hide($('region-'+f['region']));
                        (effect)($('region-'+f['region']), effect_args);
                    }
                }
            }
        } finally {
            // Re-apply the Behavior stuff
            Behaviour.apply();
            // And make the wait message go away
            hide_wait_message();
        }
    };

    // Build variable structure
    request['variables'] = {};
    var keys = current_args.keys();
    for (var i = 0; i < keys.length; i++) {
        var k = keys[i];
        request['variables']['region-'+k] = current_args[k];
    }

    // Push any state variables which we set into the forms
    for (var i = 0; i < document.forms.length; i++) {
        var form = document.forms[i];
        var keys = current_args.keys();
        for (var j = 0; j < keys.length; j++) {
            var n = keys[j];
            if (form['J:V-region-'+n]) {
                form['J:V-region-'+n].value = current_args[n];
            } else {
                var hidden = document.createElement('input');
                hidden.setAttribute('type',  'hidden');
                hidden.setAttribute('name',  'J:V-region-'+n);
                hidden.setAttribute('id',    'J:V-region-'+n);
                hidden.setAttribute('value', current_args[n]);
                form.appendChild(hidden);
            }
        }
    }

    // Set up our options
    var options = { postBody: JSON.stringify(request),
                    onComplete: onComplete,
                    requestHeaders: ['Content-Type', 'text/x-json'],
    };

    // Go!
    new Ajax.Request(document.URL,
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
                        Form.Element.getMoniker(this.element)
                        );

    entry += '&'+ encodeURIComponent("J:ACTIONS") + '=' + encodeURIComponent("autocomplete");


    this.options.parameters = this.options.callback ?
      this.options.callback(this.element, entry) : entry;

    if(this.options.defaultParams)
      this.options.parameters += '&' + this.options.defaultParams;
      
    var action =  Form.Element.getAction(this.element);
      this.options.parameters += '&' + action.serialize();

    new Ajax.Request(this.url, this.options);
  }


});

