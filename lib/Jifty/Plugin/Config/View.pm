use strict;
use warnings;

=head1 NAME

Jifty::Plugin::Config::View - Templates for Config plugin

=head1 DESCRIPTION

This provides two views for the configuration plugin.

=head2 /__jifty/config

This path (configurable by the C<config_url> setting of the plugin)
shows the L<Jifty::Plugin::Config::Action::Config> action.

=cut

package Jifty::Plugin::Config::View;
use Jifty::View::Declare -base;

__PACKAGE__->use_mason_wrapper;
my $config_url = Jifty::Plugin::Config->config_url;
my $restart_url = Jifty::Plugin::Config->restart_url;
template $config_url => sub {
    my $config = new_action( class => 'Config' );
    $config->order(1);
    my $restart = new_action( class => 'Restart' );
    $restart->order(2);
    form {
        render_action( $config );
        form_submit( label => _('Save') );
        form_submit(
            label   => _('Save and Restart'),
            # WARN: though it's an array, it doesn't mean the actions are run
            # in this order, please set ->order for each action to do this 
            submit => [ $config, $restart ],
        );
    }
};

=head2 /__jifty/config/restart.html

This path (configurable by the C<restart_url> setting of the plugin)
waits five seconds, then redirects to the configured
C<after_restart_url>.

=cut

template $restart_url => sub {
    my $seconds = get('seconds') || Jifty::Plugin::Config->wait_seconds || 5;
    my $url = get('url') || Jifty::Plugin::Config->after_restart_url;
    $url =
        Jifty->config->framework('Web')->{BaseURL} . ':'
      . Jifty->config->framework('Web')->{Port}
      . $url
      unless $url =~ /^https?:/;

    html {
        head {
            title {
                outs "Restarting ";
                outs( Jifty->config->framework('ApplicationName') );
            };
            meta {
                attr {
                    'http-equiv' => 'refresh',
                    content      => "$seconds;url=$url",
                };
            };
        };
        body {
            p {
                outs "Please wait a few moments so the server can restart, then we'll redirect you ";
                hyperlink(
                    label => "here",
                    url   => $url,
                );
                outs ".";
            }
        }
    };

    Jifty->handler->buffer->flush_output();
    $Jifty::SERVER->restart;
};

1;
