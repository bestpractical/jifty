package Jifty::Plugin::SinglePage::Dispatcher;
use strict;
use warnings;
use Jifty::Dispatcher -base;

=head1 NAME

Jifty::Plugin::SinglePage::Dispatcher - Dispatcher for SinglePage plugin

=head1 DESCRIPTION

Dispatcher for L<Jifty::Plugin::SinglePage>

=cut

before '__jifty/webservices/*' => run {
    my (@actions) = grep { $_->class eq 'Jifty::Action::Redirect' } values %{ Jifty->web->request->{'actions'} };
    $_->active(0) for @actions;

    # XXX: shouldn't have multiple redirect
    # Simply ignore Redirect from webservice if we are not in SPA
    Jifty->web->request->argument( '_webservice_redirect' => [map { $_->arguments->{url} } @actions] )
        if Jifty->find_plugin('Jifty::Plugin::SinglePage');

};

on qr{(__jifty/webservices/.*)} => run {
    my $actions = get '_webservice_redirect';
    for my $act (@$actions) {
        if ($act =~ m{^https?://}) {
            Jifty->web->request->argument( '_webservice_external_redirect' => $act );
        }
        else {
            Jifty->web->webservices_redirect($act);
        }
    }
    show $1;
};

1;
