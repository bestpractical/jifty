use warnings;
use strict;
package Jifty::Plugin::Feedback::View;

use Jifty::View::Declare -base;

=head1 NAME

Jifty::Plugin::Feedback::View

=head1 DESCRIPTION

Provides the feedback regions for L<Jifty::Plugin::Feedback>

=cut

template 'feedback/request_feedback' => sub {
    div {
        attr { id => 'feedback_wrapper' };

        h3 { _('Send us feedback!') } p {
            "Tell us what's good, what's bad, and what else you want "
                . Jifty->config->framework('ApplicationName')
                . " to do!";
        };
        render_region(
            'feedback',
            path     => "/feedback/region",
            defaults => {}
        );
    };
};


template 'feedback/region' => sub {
    my $feedback = Jifty->web->new_action(
        class   => "SendFeedback",
        moniker => "feedback"
    );

    if ( Jifty->web->response->result("feedback")) { 
    span {
        attr { id => 'feedback-result' };
        Jifty->web->response->result("feedback")->{'message'};
    };
    };
    div {
        attr { id => 'feedback' };

        form {
            render_param( $feedback => 'content' );
            form_submit(
                label   => "Send",
                onclick => {
                    submit       => $feedback,
                    refresh_self => 1
                }
            );
            }
        }
};
1;
