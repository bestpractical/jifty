use strict;
use warnings;

package Jifty::Plugin::LetMe::Dispatcher;
use Jifty::Dispatcher -base;

my $base_path = Jifty::LetMe->base_path;
my $letme_path = qr/^\Q$base_path\E/;

before qr{$letme_path(.*)$} => run {
    my $app = Jifty->config->framework('ApplicationClass');
    Jifty->api->deny(qr/^\Q$app\E::Action/) if $Jifty::Plugin::LetMe::DISABLE_ACTIONS;

    my $let_me = Jifty::LetMe->new();
    $let_me->from_token($1);
    redirect '/error/let_me/invalid_token' unless $let_me->validate;

    Jifty->web->temporary_current_user($let_me->validated_current_user);

    my %args = %{$let_me->args};
    set $_ => $args{$_} for keys %args;
    set let_me => $let_me;
};

on $letme_path => run {
    my $let_me = get 'let_me';
    show '/let/' . $let_me->path;
};

1;
