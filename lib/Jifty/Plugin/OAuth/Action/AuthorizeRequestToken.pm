package Jifty::Plugin::OAuth::Action::AuthorizeRequestToken;
use warnings;
use strict;
use base qw/Jifty::Action/;

=head1 NAME

Jifty::Plugin::OAuth::Action::AuthorizeRequestToken

=cut

use Jifty::Param::Schema;
use Jifty::Action schema {

    param 'token',
        render as 'text',
        max_length is 30,
        hints are 'The site you just came from should have provided it',
        ajax validates;

    param 'authorize',
        render as 'select',
        valid_values are qw(allow deny);

    param 'callback',
        render as 'hidden';

    param 'use_limit',
        label is 'Use limit',
        hints are 'How long should the site have access?',
        render as 'select',
        default is '1 hour',
        valid_values are (
            '5 minutes',
            '1 hour',
            '1 day',
            '1 week',
        );

    param 'can_write',
        label is 'Write access?',
        hints are 'Should the site be allowed to update your data? (unchecking restricts to read-only)',
        render as 'checkbox',
        default is 0;
};

=head2 validate_token

Make sure we have such a token, and that it is not already authorized

=cut

sub validate_token {
    my $self = shift;
    my $token = shift;

    my $request_token = Jifty::Plugin::OAuth::Model::RequestToken->new(current_user => Jifty::CurrentUser->superuser);
    $request_token->load_by_cols(
        token => $token,
        authorized => 0,
    );

    return $self->validation_error(token => "I don't know of that request token.") unless $request_token->id;

    if ($request_token->valid_until < Jifty::DateTime->now(time_zone => 'GMT')) {
        $request_token->delete();
        return $self->validation_error(token => "This request token has expired.");
    }

    return $self->validation_ok('token');
}

=head2 take_action

Actually authorize or deny this request token

=cut

sub take_action {
    my $self = shift;

    my $token = Jifty::Plugin::OAuth::Model::RequestToken->new(current_user => Jifty::CurrentUser->superuser);
    $token->load_by_cols(
        token => $self->argument_value('token'),
    );

    $self->result->content(token_obj => $token);
    $self->result->content(token     => $token->token);

    for (qw/callback use_limit can_write/) {
        $self->result->content($_ => $self->argument_value($_));
    }

    if ($self->argument_value('authorize') eq 'allow') {
        $token->set_authorized(1);
        $token->set_access_token_restrictions({
            can_write => $self->argument_value('can_write'),
            use_limit => $self->inflate_use_limit,
        });

        my $right = $self->argument_value('can_write') ? "read and write" : "read";

        $self->result->message("Allowing " . $token->consumer->name . " to $right your data for ". $self->argument_value('use_limit') .".");
    }
    else {
        $token->delete;
        $self->result->message("Denying " . $token->consumer->name . " the right to access your data.");
    }

    return 1;
}

=head2 inflate_use_limit -> DateTime

Takes the use_limit argument and inflates it to a DateTime object representing
when the access token will expire. It expects the input to be of the form
"number_of_periods period_length", so "5 minutes", "1 hour", etc.

=cut

sub inflate_use_limit {
    my $self      = shift;
    my $use_limit = $self->argument_value('use_limit');

    my ($periods, $length) = $use_limit =~ m{^(\d+)\s+(\w+)$}
        or die "AuthorizeRequestToken->inflate_use_limit failed to parse input $use_limit";

    # DateTime::Duration accepts only plurals
    $length .= 's' if $periods == 1;

    return DateTime->now->add($length => $periods);
}

1;

