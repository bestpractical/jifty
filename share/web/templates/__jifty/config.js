Jifty.Config = <% $js_config %>;
<%init>
my $config = Jifty->web->current_user->javascript_config;
my $js_config = Jifty::JSON::objToJson($config, { singlequote => 1 });
</%init>
