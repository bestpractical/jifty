#!/usr/bin/env perl
package Jifty::Plugin::OAuth::Model::AccessToken;
use strict;
use warnings;

use base qw( Jifty::Plugin::OAuth::Token Jifty::Record );

# kludge 1: you cannot call Jifty->app_class within schema {}
# kludge 3: due to the loading order, you can't really do this
#my $app_user;
#BEGIN { $app_user = Jifty->app_class('Model', 'User') }

use Jifty::DBI::Schema;
use Jifty::Record schema {

    # kludge 2: this kind of plugin cannot yet casually refer_to app models
    column auth_as =>
        type is 'integer';
        #refers_to $app_user;

    column valid_until =>
        type is 'timestamp',
        filters are 'Jifty::DBI::Filter::DateTime';

    column token =>
        type is 'varchar',
        is required;

    column secret =>
        type is 'varchar',
        is required;

    column consumer =>
        refers_to Jifty::Plugin::OAuth::Model::Consumer;

};

=head2 table

AccessTokens are stored in the table C<oauth_access_tokens>.

=cut

sub table {'oauth_access_tokens'}

=head2 is_valid

This neatly encapsulates the "is this access token perfect?" check.

This will return a (boolean, message) pair, with boolean indicating success
(true means the token is good) and message indicating error (or another
affirmation of success).

=cut

sub is_valid {
    my $self = shift;

    return (0, "Access token has no authorizing user")
        if !$self->auth_as;

    return (0, "Access token expired")
        if $self->valid_until < DateTime->now;

    return (1, "Request token valid");
}

1;

