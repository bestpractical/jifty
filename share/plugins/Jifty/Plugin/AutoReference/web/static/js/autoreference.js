if (!Jifty.Plugin) Jifty.Plugin = {};

Jifty.Plugin.AutoReference = Class.create();
Object.extend(Object.extend(Jifty.Plugin.AutoReference.prototype, Jifty.Autocompleter.prototype), {
    initialize: function(field, hiddenField, div) {
        this.hiddenField = $(hiddenField);

        // Copied from Jifty.Autocompleter.initialize
        this.field  = $(field);
        this.action = Form.Element.getAction(this.hiddenField);
        this.url    = '/__jifty/autocomplete.xml';

        Event.observe(this.field, "focus", this.onFocus.bindAsEventListener(this));
        this.baseInitialize(this.field, $(div), {
            minChars: "0",
            beforeShow: this.beforeShow,
            beforeHide: this.beforeHide,
            frequency: 0.1,
            onShow: this.onShow,
            onHide: this.onHide,
            updateElement: this.updateElment,
            afterUpdateElement: this.afterUpdate
        });
    },

    updateElement: function(selection) {
        var label = Element.collectTextNodes(document.getElementsByClassName('informal', selection)[0]);
        var value = Element.collectTextNodes(document.getElementsByClassName('hidden_value', selection)[0]);

        this.field.value = label;
        this.hiddenField.value = value;
    },

    afterUpdate: function(field, selection) {
        
        Form.Element.validate(this.hiddenField);
    },

    getUpdatedChoices: function() {
        var request = { path: this.url, actions: {} };

        var a = $H();
        a['moniker'] = 'autocomplete';
        a['class']   = 'Jifty::Action::Autocomplete';
        a['fields']  = $H();
        a['fields']['moniker']  = this.action.moniker;
        a['fields']['argument'] = Form.Element.getField(this.field);
        request['actions']['autocomplete'] = a;
        request['actions'][this.action.moniker] = this.action.data_structure();
        request['actions'][this.action.moniker]['active']  = 0;

        // Fix up the field to use the real field instead of the hidden one
        var value = this.field.value.replace(/\s*\[(?:i(?:d(?::(?:\s*(?:\d+\]?)?)?)?)?)?$/, '')
        request['actions'][this.action.moniker]['fields'][a['fields']['argument']]['value'] = value;

        var options = { postBody: JSON.stringify(request),
            onComplete: this.onComplete.bind(this),
            requestHeaders: ['Content-Type', 'text/x-json']
        };

        new Ajax.Request(this.url,
                options
                );
    }

});
