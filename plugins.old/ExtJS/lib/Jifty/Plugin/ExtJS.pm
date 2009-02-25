use strict;
use warnings;

=head1 NAME

Jifty::Plugin::ExtJS - Use the Ext javascript library

=cut

package Jifty::Plugin::ExtJS;
use base qw/Jifty::Plugin/;

=head1 SYNOPSIS

In etc/config.yml

    Plugins:
      - ExtJS: {}

If you want to include javascript files by hand:

    Plugins:
      - ExtJS:
        IncludeDefault: 0

You have to include Ext's CSS file by hand. Just add this line in main.css:

    @import "extjs/ext-all.css";


=head1 DESCRIPTION

ExtJS plugin contains necessary files to run Ext JavaScript library.
Ext supports YUI, prototype and jQuery. This plugin uses YUI by default.

    Ext: http://extjs.com/

=cut

sub init {
    my $self = shift;
    my %args = (IncludeDefault => 1, @_);

    return unless $args{IncludeDefault};

    Jifty->web->javascript_libs([
        "extjs/adapter/yui/yui-utilities.js",
        "extjs/adapter/yui/ext-yui-adapter.js",
        "extjs/ext-all.js",
        "extjs/ext-config.js",
        @{ Jifty->web->javascript_libs }
    ]);
}

1;
