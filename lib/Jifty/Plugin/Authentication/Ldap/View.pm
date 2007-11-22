use utf8;
use warnings;
use strict;

=head1 NAME Jifty::Plugin::Authentication::Ldap::View

This provides the templates for the pages and forms used by the ldap authentication plugin.

=cut

package Jifty::Plugin::Authentication::Ldap::View;
use Jifty::View::Declare -base;

{ no warnings 'redefine';
sub page (&;$) {
    no strict 'refs';
    BEGIN {Jifty::Util->require(Jifty->app_class('View'))};
    Jifty->app_class('View')->can('page')->(@_);
}
}

template ldaplogin => page { title => _('Login!') } content {
    show('/ldaplogin_widget');
};


template ldaplogin_widget => sub {
#    title is _("Login with your Ldap account") 

    my ( $action, $next ) = get( 'action', 'next' );
    $action ||= new_action( class => 'LDAPLogin' );
    $next ||= Jifty::Continuation->new(
        request => Jifty::Request->new( path => "/" ) );
    unless ( Jifty->web->current_user->id ) {
        h3  { _('Login with your ldap account') };
        div {
            attr { id => 'jifty-login' };
            Jifty->web->form->start( call => $next );
            render_param( $action, 'ldap_id', focus => 1 );
            render_param( $action, 'password' );
            form_return( label => _(q{Login}), submit => $action );
            Jifty->web->form->end();
        };
    } else {
        outs( _("You're already logged in.") );
    }
};


1;
