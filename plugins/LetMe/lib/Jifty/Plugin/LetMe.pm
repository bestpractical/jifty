use strict;
use warnings;

=head1 NAME

Jifty::Plugin::LetMe

=cut

package Jifty::Plugin::LetMe;
use base qw/Jifty::Plugin/;

=head1 DESCRIPTION

C<Jifty::Plugin::LetMe> provides a simple way to enable URLs generated
by L<Jifty::LetMe/as_url>.

When a user follows a URL created by
L<Jifty::LetMe::as_url|Jifty::LetMe/as_url>, C<Jifty::Plugin::LetMe>
will check if the URL is valid, and, if so, set request arguments for
each of C<$letme->args>, as well as setting the request argument
C<let_me> to the decoded LetMe itself. It will then show the Mason
component C<< '/let/' . $letme->path >>.

By default, we disable all application actions
(C<I<AppName>::Action::*>) on LetMe URLs. To disable this behavior,
pass the argument C<DisableActions: 0> to the plugin in your
C<config.yml>. It's probably a better idea, however, to only enable
specific actions in your own dispatcher, e.g.:

    after plugin 'Jifty::Plugin::LetMe' =>
    before qr'^/let' => run {
        my $let_me = get 'let_me';
        Jifty->api->allow('ConfirmEmail') if $let_me->path eq 'confirm';
    };

=cut

our $DISABLE_ACTIONS = 1;

sub init {
    my $self = shift;
    my %args = (DisableActions => 1,
                @_);
    $DISABLE_ACTIONS = $args{DisableActions};
}

1;
