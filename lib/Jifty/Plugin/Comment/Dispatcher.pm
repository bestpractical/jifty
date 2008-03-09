use strict;
use warnings;

package Jifty::Plugin::Comment::Dispatcher;
use Jifty::Dispatcher -base;

use DateTime::Format::Mail;
use DateTime::Format::W3CDTF;
use Jifty::DateTime;
use Scalar::Util qw/ blessed looks_like_number /;

sub setup_parent_object() {
    my $parent;
    unless (get 'parent') {
        my ($parent_class, $parent_id) = @_;
        if (get 'comment_upon') {
            my $comment_upon = get 'comment_upon';
            ($parent_class, $parent_id) = $comment_upon =~ /^([\w:]+)-(\d)$/;
        }
        else {
            $parent_class = get 'parent_class';
            $parent_id    = get 'parent_id';
        }

        abort 404 unless $parent_class and $parent_id;
        abort 500 unless $parent_class =~ /^[\w:]+$/;
        abort 500 unless eval { $parent_class->isa('Jifty::Record') };
        abort 500 unless looks_like_number($parent_id);

        $parent = $parent_class->new;
        $parent->load($parent_id);

        set parent => $parent;
    }

    else {
        $parent = get 'parent';
    }

    abort 500 unless eval { $parent->isa('Jifty::Record') };
    abort 500 unless eval { $parent->can('comments') };
    abort 404 unless eval { $parent->id };

}

on 'comment/list' => run {
    setup_parent_object();
    show '/comment/list';
};

on 'comment/add' => run {
    setup_parent_object();

    my $parent = get 'parent';

    my $action = Jifty->web->new_action( 
        class => 'CreateComment',
        moniker => 'add-comment-'.$parent->id,
        arguments => {
            parent_class => blessed $parent,
            parent_id    => $parent->id,
        },
    );
    $action->argument_value( title => get('title') || '')
        unless $action->argument_value('title');
    set action => $action;

    show '/comment/add';
};

on 'comment/display' => run {
    my $id = get 'id';

    my $comment = Jifty->app_class('Model', 'Comment')->new;
    $comment->load($id);

    if (get 'update_status') {
        my $action = $comment->as_update_action;
        $action->argument_value( status => get 'update_status' );
        $action->run;

        Jifty->web->response->result( $action->moniker => $action->result );
    }

    if (defined get 'update_published') {
        my $action = $comment->as_update_action;
        $action->argument_value( published => get 'update_published' );
        $action->run;

        Jifty->web->response->result( $action->moniker => $action->result );
    }

    set comment => $comment;
};

1;
