Class("JiftyClient", {
    has: {
        baseUrl: {
            is: "rw"
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
                url: "/=/action/" + name + ".json",
                data: params,
                dataType: "json",
                type: 'POST',
                error: onFailure,
                success: onAjaxSuccess
            });
        }
    }
});

