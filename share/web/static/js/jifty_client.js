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
        mirrorModel: function (modelName, className, onSuccess, onFailure) {
            var that = this;
            jQuery.ajax({
                url: this._includeBaseUrl("/=/model/" + modelName + ".json"),
                dataType: "json",
                type: 'GET',
                error: onFailure,
                success: function (result) {
                    onSuccess(that.buildClassFromModel(result, className));
                }
            });
        },
        buildClassFromModel: function (classStructure, className) {
        }
    }
});

