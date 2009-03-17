Jifty.Config = <% $js_config |n%>;
<%init>
my $config = Jifty->web->current_user->javascript_config;
my $js_config = Jifty::JSON::objToJson($config);
</%init>
