function getPasswordToken(moniker) {
    var url = "/__jifty/webservices/xml";

    var action = new Action(moniker);
    var token_field = action.getField("token");
    var hashedpw_field = action.getField("hashed_password");

    if (!token_field || !hashedpw_field)
        return true;

    var parseToken = function(request, responseStatus) {
        var myform    = action.form;

        var response  = request.documentElement;
        var token     = response.getElementsByTagName("token")[0].firstChild.nodeValue;
        var salt      = response.getElementsByTagName("salt")[0].firstChild;
        if (!salt)
            return;
        salt          = salt.nodeValue;

        if (token != "") {  // don't hash passwords if no token
            var password_field = action.getField("password");
            var password = password_field.value;
            hashedpw_field.value = Digest.MD5.md5Hex(token + " " + Digest.MD5.md5Hex(password + salt));
            token_field.value = token;

            // Clear password so it won't get submitted in cleartext.
            password_field.value = "";
        }
        myform.submit();
    };

    var request = { path: url, actions: {} };
    var a = {};
    a["moniker"] = "login";
    a["class"]   = "GeneratePasswordToken";
    a["fields"]  = {};
    if (action.getField("username"))
        a["fields"]["username"]  = action.getField("username").value;
    if (action.getField("email"))
        a["fields"]["email"]     = action.getField("email").value;
    request["actions"]["login"] = a;

    jQuery.ajax({
        url: url,
        type: "post",
        data: JSON.stringify(request),
        contentType: 'text/x-json',
        dataType: 'xml',
        success: parseToken
    });

    return false;
}
