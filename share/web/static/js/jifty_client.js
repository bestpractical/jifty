Class("JiftyModel", {
    methods: {
        syncDiff: function (diff, onSuccess, onFailure) {
            var className = this.meta.getName();
            var actionName = "Update" + className;

            // this is always required, but if someone is doing something
            // bizarre, let them
            if (!diff.id) {
                diff.id = this.id;
            }

            // should we abort if diff contains only id?

            this.meta.getClassObject().jiftyClient.runAction(actionName, diff, onSuccess, onFailure);
        },
        sync: function (onSuccess, onFailure) {
            var record = this;
            var diff = {};

            var original = record._original;

            if (!original) {
                console.log("This record seems to have no _original field; unable to compute diff.", record);
            }

            this.meta.getClassObject().eachColumn(function (column, name) {
                if (record[name] != original[name]) {
                    diff[name] = record[name];
                }
            });

            this.syncDiff(diff, onSuccess, onFailure);
        }
    },
    classMethods: {
        load: function (id, onSuccess, onFailure) {
            var that = this;
            var className = this.meta.getName();
            var jiftyClient = this.jiftyClient;

            var onAjaxSuccess = function (result) {
                if (result.id) {
                    onSuccess(jiftyClient.inflateRecord(result, className));
                }
                else {
                    onFailure(result);
                }
            };

            jiftyClient.fetchRecord(className, id, onAjaxSuccess, onFailure);
        },
        eachColumn: function (callback) {
            Joose.O.eachSafe(this.meta.getAttributes(), function (attr, name) {
                if (attr.getProps().jiftyColumn) {
                    callback(attr, name);
                }
            });

        }
    }
});

Class("JiftyClient", {
    has: {
        baseUrl: {
            is: "rw",
            predicate: "hasBaseUrl"
        },
        email: {
            is: "rw"
        },
        password: {
            is: "rw"
        },
        currentUser: {
            is: "rw"
        }
    },
    methods: {
        login: function (onSuccess, onFailure) {
            var that = this;
            this.runAction(
                "Login",
                {
                    address:  this.email,
                    password: this.password
                },
                function (result) {
                    that.aboutMe(function () {
                        onSuccess(result);
                    }, onFailure);
                },
                onFailure
            );
        },
        aboutMe: function (onSuccess, onFailure) {
            var that = this;
            this.runAction(
                "AboutMe",
                {},
                function (result) {
                    that.currentUser = result.content.current_user;
                    onSuccess(result);
                },
                onFailure
            );
        },
        _includeBaseUrl: function (path) {
            var url = path;
            if (this.hasBaseUrl()) {
                url = this.baseUrl + url;
            }
            return url;
        },
        runAction: function (name, params, onSuccess, onFailure) {
            // if the action returns failure then we want to run the onFailure
            // handler, even though the AJAX request was successful
            var onAjaxSuccess = function (result) {
                // on an Update action, we are redirected to a GET of the object
                // which will (probably..) not have a success field. argh. is
                // there anything better we can do here?
                if (result.success === 0) {
                    onFailure(result);
                }
                else {
                    onSuccess(result);
                }
            };

            jQuery.ajax({
                url: this._includeBaseUrl("/=/action/" + name + ".json"),
                data: params,
                dataType: "json",
                type: 'POST',
                error: onFailure,
                success: onAjaxSuccess
            });
        },
        fetchRecord: function (className, id, onSuccess, onFailure) {
            jQuery.ajax({
                url: this._includeBaseUrl("/=/model/" + className + "/id/" + id + ".json"),
                dataType: "json",
                type: 'GET',
                error: onFailure,
                success: onSuccess
            });
        },
        mirrorModel: function (modelName, onSuccess, onFailure) {
            var that = this;

            var onAjaxSuccess = function () {
                var c = that.meta.classNameToClassObject(modelName);
                c.jiftyClient = that;
                onSuccess(c);
            };

            jQuery.ajax({
                url: this._includeBaseUrl("/=/model/" + modelName + ".joose"),
                dataType: "script",
                type: 'GET',
                error: onFailure,
                success: onAjaxSuccess
            });
        },
        inflateRecord: function (result, className) {
            var c = this.meta.classNameToClassObject(className);

            // Joose really doesn't like when you pass an explicit "null"
            // for an attribute with a type constraint, so we need to clear
            // those
            Joose.O.eachSafe(result, function (value, field) {
                if (value === null) {
                    delete result[field];
                }
            });

            var record = c.meta.instantiate(result);
            record._original = result;
            return record;
        }
    }
});

