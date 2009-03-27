use strict;
use warnings;

package Jifty::Plugin::Config;
use base qw/Jifty::Plugin/;

=head2 NAME

Jifty::Plugin::Config - Add configuration editor

=head2  DESCRIPTION

This plugin provides a basic configuration editor for your application.
Basically, it tries to help you update the most important items in Jifty's config
file, so you don't need to edit the config file directly.

the updated config file will be saved in file $EVN{JIFTY_SITE_CONFIG} or
etc/site_config.yml

This plugin is designed mostly for beginners ;)

=cut

1;

