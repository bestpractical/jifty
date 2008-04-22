use warnings;
use strict;

=head1 NAME

Jifty::Plugin::OpenID::Action::VerifyOpenID;

=cut

package Jifty::Plugin::OpenID::Action::VerifyOpenID;
use base qw/Jifty::Action/;

use Net::OpenID::Consumer;
use Cache::FileCache;

=head2 arguments

No args

=cut

sub arguments { return ( {} ) }

=head2 take_action

Check the result of the login.  If it's good, load the user
and log them in.  Otherwise, throw an error.

=cut

sub take_action {
    my $self = shift;

# XXX HACK: some OpenID servers (LJ and myopenid.com included) don't seem
# to properly escape plus signs (+) in openid.sig when returning the user
# back to us.  We need to convert the pluses back from spaces to pluses again.
    my $sig = Jifty->handler->cgi->param('openid.sig');
    $sig =~ s/ /+/g;
    Jifty->handler->cgi->param( 'openid.sig' => $sig );

    my $csr = Jifty::Plugin::OpenID->get_csr;

    if ( my $setup = $csr->user_setup_url ) {
        Jifty->web->_redirect($setup);
    }
    elsif ( $csr->user_cancel ) {
        $self->result->error(
            _(  'OpenID verification failed.  It looks like you cancelled the OpenID verification request.'
            )
        );
        return;
    }

    my $ident = $csr->verified_identity;

    if ( not defined $ident ) {
        $self->result->error( _('OpenID verification failed: ') . $csr->err );
        return;
    }

    Jifty->log( "identified as: " . $ident->url );
    $self->result->content( openid => $ident->url );

    return 1;
}

1;
