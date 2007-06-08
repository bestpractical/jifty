package Jifty::Plugin::SinglePage::Dispatcher;
use strict;
use warnings;
use Jifty::Dispatcher -base;

before '__jifty/webservices/*' => run {
    my (@actions) = grep { $_->class eq 'Jifty::Action::Redirect' } values %{ Jifty->web->request->{'actions'} };
    $_->active(0) for @actions;

    # XXX: shouldn't have multiple redirect
    # Simply ignore Redirect from webservice if we are not in SPA
    set '_webservice_redirect' => [map { $_->arguments->{url} } @actions]
        if Jifty->find_plugin('Jifty::Plugin::SinglePage');

};

on qr{(__jifty/webservices/.*)} => run {
    my $actions = get '_webservice_redirect';
    Jifty->web->request->remove_state_variable('region-__page');
    for my $act (@$actions) {
	if ($act =~ m{^https?://}) {
	    set '_webservice_external_redirect' => $act;
	}
	else {
	    Jifty->web->request->add_fragment(
                name      => '__page',
                path      => $act,
                arguments => {},
                wrapper   => 0
            );
	}
    }
    show $1;
};

1;
