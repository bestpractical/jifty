use strict;
use warnings;

package Jifty::Plugin::Debug;
use base qw/Jifty::Plugin/;

=head1 NAME

Jifty::Plugin::Debug - a plugin to log each incoming request

=head1 DESCRIPTION

Enable this plugin in your F<etc/config.yml> (requires no configuration) and the plugin add an INFO level log message on each request received. It will contain the PID of the current process, the URL requested, and the username (if any) of the person making the request.

=cut

1;
