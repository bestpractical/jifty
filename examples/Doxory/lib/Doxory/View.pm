package Doxory::View;
use utf8;
use strict;
use warnings;
use Jifty::View::Declare -base;

template '/' => page {
    h1 { _('Ask a question!') }
    div { show 'new_choice' }
};

private template new_choice => sub {
    form {
        my $action = new_action( class => 'CreateChoice' );
        render_action( $action => ['name', 'a', 'b'] );
        form_submit( label => _('Ask the crowd!') );
    }
};

template choices => page {
    h1 { 'My Choices' }
    dl {
        my $choices = Doxory::Model::ChoiceCollection->new;
        $choices->limit(
            column  => 'asked_by',
            value   => Jifty->web->current_user->id,
        );
        while (my $c = $choices->next) {
            dt { $c->name, ' (', $c->asked_by->name, ')' }
            dd { 
            b { $c->a, ' (', $c->in_favor_of_a->count, ')' }
            em { 'vs' }
            b { $c->b, ' (', $c->in_favor_of_b->count, ')' }
            }
        }
    }
};

template pick => page {
    my $choice = get('choice');
    my $action = new_action( class => 'CreateVote' );
    my $redir  = new_action(
        class     => "Jifty::Action::Redirect",
        arguments => { url => '/pick' },
    );
    # XXX - For some reason passing it in on the previous line doesn't work.
    my %args   = (
        choice => $choice->id,
        voter  => Jifty->web->current_user->id,
    );

    h1 { $choice->asked_by->name, ': ', $choice->name }
    div { form {
        my ($x, $y) = map { $action->button(
            submit      => [ $action, $redir ],
            label       => $choice->$_,
            arguments   => { suggestion => $_, %args },
        ) } ((rand > 0.5) ? ('a', 'b') : ('b', 'a'));

        span { $x } em { 'or' } span { $y } em { 'or' } span {
            $action->button(
                submit      => [ $action, $redir ],
                label       => 'None of the above',
                arguments   => { suggestion => 'skip', %args },
            );
        }

        p { render_param( $action => 'comments' ) }
    } }
};

template nothing_to_pick => page {
    h1 { "There's nothing for you to pick." }

    p { "No one you know is angsting about anything. Everybody knows where
         they're going to dinner, what to do on their next date and whether to
         drop that class. You have such lovely and well adjusted friends." }

    h2 { "Maybe it's time to ask for some advice..." };

    show 'new_choice';
};

1;
