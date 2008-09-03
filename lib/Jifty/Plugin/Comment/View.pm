use strict;
use warnings;

package Jifty::Plugin::Comment::View;
use Jifty::View::Declare -base;

use Jifty::DateTime;

=head1 NAME

Jifty::Plugin::Comment::View - the templates for the comment plugin

=head1 DESCRIPTION

=head1 METHODS

=head2 scrub_html

This is a utility used internally for cleaning up the input which might come from a malicious source.

=cut

sub scrub_html($) {
    my $text = shift;

    my $plugin = Jifty->find_plugin('Jifty::Plugin::Comment');
    return $plugin->scrubber->scrub($text);
}

=head1 TEMPLATES

=head2 __comment/view

This displays a single comment in a page.

=cut

template '__comment/view' => page {
    my $comment = get 'comment';

    { title is _( $comment->title ); }

    div {
        { class is 'column span-21 first' }

        render_region
            name => 'comment-'.$comment->id,
            path => '/__comment/display',
            defaults => {
                id  => $comment->id,
                top => 1,
            },
            ;
    };

    show '/advertisement';
};

=head2 __comment/display

Display a comment in a page region.

=cut

template '__comment/display' => sub {
    my $comment = get 'comment';
    my $top     = get 'top';

    my $plugin = Jifty->find_plugin('Jifty::Plugin::Comment');

    div {
        my $class = 'comment';
        $class .= $comment->status eq 'ham' ? ' ham' : ' spam'
            if Jifty->web->current_user->id;
        $class .= $comment->published ? ' published' : ' unpublished';

        { class is $class }

        div {
            { class is 'actions' }

            if (Jifty->web->current_user->id) {

                for my $status (qw( ham spam )) {
                    if ($comment->status ne $status && $plugin->akismet) {
                        hyperlink
                            label => _('mark as %1', $status),
                            onclick => {
                                args  => {
                                    update_status => $status,
                                },
                            },
                            ;
                    }
                }

                for my $published (0, 1) {
                    if ($comment->published ne $published) {
                        hyperlink
                            label => $published ? _('publish') : _('unpublish'),
                            onclick => {
                                args  => {
                                    update_published => $published,
                                },
                            },
                            ;
                    }
                }
            }

            '';
        };

        unless ($top) {
            if ($comment->status eq 'ham' && $comment->published) {
                h5 { 
                    a {
                        attr { name => 'comment-'.$comment->id };
                        $comment->title 
                    };
                };
            };
        };

        div {
            { class is 'comment-info' }

            my $poster = $comment->your_name || 'Anonymous Coward';
            $poster = Jifty->web->escape($poster);
            $poster = qq{<a href="@{[$comment->web_site]}">$poster</a>}
                if $comment->web_site;

            my $created_on = $comment->created_on;

            p { 
                outs_raw _('By %1 %2', 
                    $poster, 
                    $created_on->strftime('%A, %B %d, %Y @ %H:%M%P')
                ) 
            };
        };

        if ($comment->status eq 'ham' && $comment->published) {
            div {
                outs_raw scrub_html($comment->body);
            };
        };

    };
};

=head2 __comment/add

This presents the form for adding a new comment.

=cut

template '__comment/add' => sub {
    my $collapsed = get 'collapsed';
    my $region    = get 'region';

    if ($collapsed) {
        p {
            hyperlink
                label => _('Add a comment'),
                onclick => {
                    refresh_self => 1,
                    args => { collapsed => 0 },
                },
                ;
        };
    }

    else {
        my $action = get 'action';

        if (get 'preview') {
            div {
                { class is 'preview comment' }

                h5 { $action->argument_value('title') || 'No Title' };

                div {
                    { class is 'comment-info' }

                    my $poster = $action->argument_value('your_name') 
                              || 'Anonymous Coward';
                    $poster = Jifty->web->escape($poster);
                    $poster = qq{<a href="@{[$action->argument_value('web_site')]}">$poster</a>}
                        if $action->argument_value('web_site');

                    my $created_on = Jifty::DateTime->now;

                    p { 
                        outs_raw _('By %1 %2', 
                            $poster, 
                            $created_on->strftime('%A, %B %d, %Y @ %H:%M%P')
                        ) 
                    };
                };

                div {
                    my $body = $action->argument_value('body')
                            || 'No Body';

                    outs_raw scrub_html($body);
                };
            };
        };

        div {
            { class is 'edit comment' }

            form {
                render_action $action;

                div {
                    { class is 'submit-buttons' }

                    form_submit
                        label => _('Preview'),
                        name => 'op',
                        class => 'first',
                        onclick => {
                            refresh_self => 1,
                            submit => { 
                                action => $action, 
                                arguments => { submit => 0 },
                            },
                            args => { preview => 1 },
                        },
                        ;

                    if (get 'preview') {
                        form_submit
                            label => _('Submit'),
                            onclick => [ 
                                {
                                    refresh_self => 1,
                                    submit => {
                                        action => $action,
                                        arguments => { submit => 1 },
                                    },
                                    args => {
                                        preview => 0,
                                        collapsed => 1,
                                    },
                                },
                                {
                                    element => $region->parent->get_element('div.list'),
                                    append  => '/__comment/display',
                                    args    => {
                                        id  => { result => $action, name => 'id' },
                                        top => 0,
                                    },
                                },
                            ],
                            ;
                    }
                };
            };
        };
    }
};

=head2 __comment/list

This presents a list of comments attached to a particular comment and the form for adding one more.

=cut

template '__comment/list' => sub {
    my $parent   = get 'parent';
    my $title    = get 'initial_title';
    my $comments = $parent->comments;

    if (!Jifty->web->current_user->id) {
        $comments->limit(
            column => 'status',
            value  => 'ham',
        );
    }

    div {
        { class is 'list' }

        if ($comments->count) {
            while (my $comment = $comments->next) {
                render_region
                    name => 'comment-'.$comment->id,
                    path => '/__comment/display',
                    defaults => {
                        id  => $comment->id,
                        top => 0,
                    },
                    ;
            }
        }

        else {
            p {
                { class is 'none' }

                _('No one has made a comment yet.');
            };
        }
    };

    unless (get 'no_add') {
        render_region
            name     => 'comment-add-'.$parent->id,
            path     => '/__comment/add',
            defaults => {
                parent_class => ref $parent,
                parent_id    => $parent->id,
                collapsed    => 1,
                title        => $title,
            },
            ;
    }
};

=head1 SEE ALSO

L<Jifty::View::Declare>

=head1 AUTHOR

Andrew Sterling Hanenkamp, C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
