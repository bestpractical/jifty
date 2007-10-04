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
    }
});
