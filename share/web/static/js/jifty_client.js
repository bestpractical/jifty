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
            jQuery.ajax({
                url: "/=/action/" + name + ".json",
                async: false,
                data: params,
                dataType: "json",
                type: 'POST',
                error: onFailure,
                success: onSuccess
            });
        }
    }
});

