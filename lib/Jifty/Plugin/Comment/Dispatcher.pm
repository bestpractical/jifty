use strict;
use warnings;

package Jifty::Plugin::Comment::Dispatcher;
use Jifty::Dispatcher -base;

use Scalar::Util qw/ blessed looks_like_number /;

=head1 NAME

Jifty::Plugin::Comment::Dispatcher - dispatcher for the comment plugin

=head1 DESCRIPTION

Handles the dispatch of the C<__comment> paths used by this plugin.

=head1 METHODS

=head2 setup_parent_object

Called internally by the dispatcher rules to create the "parent" dispatcher argument from "comment_upon" or "parent_class" and "parent_id".

=cut

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

=head1 RULES

=head2 __comment/list

Sets up the "parent" argument for the list template.

=cut

on '__comment/list' => run {
    setup_parent_object();
};

=head2 __comment/add

Set up the "parent" argument for the add template and set the "CreateComment" action into the "action" argument.

=cut

on '__comment/add' => run {
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

    show '/__comment/add';
};

=head2 __comment/display

Sets up the "comment" argument and will update the status and published values of the comment if "update_status" or "update_published" are set, respectively.

=cut

on '__comment/display' => run {
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

=head1 SEE ALSO

L<Jifty::Dispatcher>

=head1 AUTHOR

Andrew Sterling Hanenkamp, C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
