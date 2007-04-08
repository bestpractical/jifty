package Doxory::Dispatcher;
use strict;
use warnings;
use Jifty::Dispatcher -base;

before '*' => run {
    if (Jifty->web->current_user->id) {
        my $top = Jifty->web->navigation;
        $top->child( 'Pick!'    => url => '/pick' );
        $top->child( 'Choices'  => url => '/choices' );
    }
    elsif ($1 !~ /^login|^signup/) {
        tangent 'login';
    }
};

#on '/' => show 'new_choice';

on pick => run {
    my $choices = Doxory::Model::ChoiceCollection->new;
    my $votes   = $choices->join(
        type    => 'left',
        alias1  => 'main',  column1 => 'id',
        table2  => 'votes', column2 => 'choice',
    );
    $choices->limit(
        leftjoin => $votes, column => 'voter',
        value    => Jifty->web->current_user->id,
    );
    $choices->limit(
        alias    => $votes, column => 'voter',
        operator => 'IS',   value => 'NULL',
    );

    if (my $c = $choices->first) {
        set choice => $c;
    }
    else {
        show 'nothing_to_pick';
    }
};

1;
