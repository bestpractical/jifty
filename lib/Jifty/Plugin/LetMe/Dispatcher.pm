use strict;
use warnings;

package Jifty::Plugin::LetMe::Dispatcher;
use Jifty::Dispatcher -base;

=head1 NAME

Jifty::Plugin::LetMe::Dispatcher - Dispatcher for LetMe plugin

=head1 DESCRIPTION

All the dispatcher rules jifty needs to support L<Jifty::LetMe/>

=cut

## LetMes
before qr'^/let/(.*)' => run {
    my $let_me = Jifty::LetMe->new();
    $let_me->from_token($1);
    redirect '/error/let_me/invalid_token' unless $let_me->validate;
    Jifty->web->temporary_current_user( $let_me->validated_current_user );

    my %args = %{ $let_me->args };
    set $_ => $args{$_} for keys %args;
    set let_me => $let_me;
};

on qr'^/let/' =>
    run { my $let_me = get 'let_me'; show '/let/' . $let_me->path; };

1;
