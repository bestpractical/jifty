Localization = Object.extend(new Object(), {
    init: function(params) {
        this.lang = params.lang || 'en'
        if (params["dict_path"]) {
            this.dict_path = params["dict_path"]
            this.dict = this.load_dict(this.lang)
        }
        Ext.onReady(function() {
            Localization.show_dates_as_local_time();
        })
    },
    switch_dict: function(lang) {
        this.dict = this.load_dict(lang);
    },
    load_dict: function(lang) {
        var d;
        new Ajax.Request(
            this.dict_path + "/" + lang + ".json",
            {
                method: 'get',
                asynchronous: false,
                onComplete: function(t, obj) {
                    eval("d = " + t.responseText || "{}");
                }
            }
        );
        return d;
    },
    loc: function(str) {
        var dict = this.dict
        if (dict[str]) {
            return dict[str]
        }
        return str
    },

    show_dates_as_local_time: function() {
        var spans = document.getElementsByTagName('span');
        for (var i=0; i<spans.length; i++) {
            if (spans[i].className.match(/\bdatetime\b/i)) {
                var d = this.get_local_time_for_date(spans[i].title);
                if (d != 'NaN') {
                    spans[i].innerHTML = d
                }
            }
        }
    },

    get_local_time_for_date: function(time) {
        system_date = new Date(time);
        user_date = new Date();
        delta_minutes = Math.floor((user_date - system_date) / (60 * 1000));
        if (Math.abs(delta_minutes) <= (7*24*60)) {
            distance = this.distance_of_time_in_words(delta_minutes);
            if (delta_minutes < 0) {
                return distance + _(' from now');
            } else {
                return distance + _(' ago');
            }
        } else {
            return system_date.toLocaleDateString();
        }
    },

    distance_of_time_in_words: function(minutes) {
        if (minutes.isNaN) return "";
        minutes = Math.abs(minutes);
        if (minutes < 1) return _('less than a minute');
        if (minutes < 50) return _(minutes + ' minute' + (minutes == 1 ? '' : 's'));
        if (minutes < 90) return _('about one hour');
        if (minutes < 1080) return (Math.round(minutes / 60) + ' hours');
        if (minutes < 1440) return _('one day');
        if (minutes < 2880) return _('about one day');
        else return (Math.round(minutes / 1440) + _(' days'))
    }

})

_ = Localization.loc.bind(Localization)

