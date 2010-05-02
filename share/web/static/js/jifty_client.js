Class("JiftyModel", {
    classMethods: {
        load: function (id, onSuccess, onFailure) {
            var that = this;
            var className = this.meta.getName();

            var onAjaxSuccess = function (result) {
                if (result.id) {
                    var record = that.meta.instantiate(result);
                    record.jiftyClient = that.jiftyClient;
                    onSuccess(record);
                }
                else {
                    onFailure(result);
                }
            };

            this.jiftyClient.loadById(className, id, onAjaxSuccess, onFailure);
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
        }
    },
    methods: {
        login: function (onSuccess, onFailure) {
            this.runAction(
                "Login",
                {
                    address:  this.email,
                    password: this.password
                },
                onSuccess,
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
                if (result.success) {
                    onSuccess(result);
                }
                else {
                    onFailure(result);
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
        loadById: function (className, id, onSuccess, onFailure) {
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
        }
    }
});

