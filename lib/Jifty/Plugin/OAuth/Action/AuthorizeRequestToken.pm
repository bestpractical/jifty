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
        valid_values are qw(allow deny);

    param 'callback',
        render as 'hidden';

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
        authorized => '',
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
    $self->result->content(callback  => $self->argument_value('callback'));

    if ($self->argument_value('authorize') eq 'allow') {
        $token->set_authorized('t');
        $self->result->message("Allowing " . $token->consumer->name . " to access your stuff.");
    }
    else {
        $token->delete;
        $self->result->message("Denying " . $token->consumer->name . " the right to access your stuff.");
    }

    return 1;
}

1;

