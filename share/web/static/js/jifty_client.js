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

