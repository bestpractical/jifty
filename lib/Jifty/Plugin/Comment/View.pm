use strict;
use warnings;

package Jifty::Plugin::Comment::View;
use Jifty::View::Declare -base;

use Jifty::DateTime;

sub scrub_html($) {
    my $text = shift;

    my $plugin = Jifty->find_plugin('Jifty::Plugin::Comment');
    return $plugin->scrubber->scrub($text);
}

template 'comment/view' => page {
    my $comment = get 'comment';

    { title is _( $comment->title ); }

    div {
        { class is 'column span-21 first' }

        render_region
            name => 'comment-'.$comment->id,
            path => '/comment/display',
            defaults => {
                id  => $comment->id,
                top => 1,
            },
            ;
    };

    show '/advertisement';
};

template 'comment/display' => sub {
    my $comment = get 'comment';
    my $top     = get 'top';

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
                    if ($comment->status ne $status) {
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
                            label => _($published ? 'publish' : 'unpublish'),
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
            h5 { 
                a {
                    attr { name => 'comment-'.$comment->id };
                    $comment->title 
                };
            };
        }

        div {
            { class is 'comment-info' }

            my $poster = $comment->your_name || 'Anonymous Coward';
            $poster = Jifty->web->escape($poster);
            $poster = qq{<a href="@{[$comment->web_site]}">$poster</a>}
                if $comment->web_site;

            my $created_on = Jifty::DateTime->now;

            p { 
                outs_raw _('By %1 %2', 
                    $poster, 
                    $created_on->strftime('%A, %B %d, %Y @ %H:%M%P')
                ) 
            };
        };

        div {
            outs_raw scrub_html($comment->body);
        };

    };
};

template 'comment/add' => sub {
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
                                    append  => '/comment/display',
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

template 'comment/list' => sub {
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
                    path => '/comment/display',
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
            path     => '/comment/add',
            defaults => {
                parent_class => ref $parent,
                parent_id    => $parent->id,
                collapsed    => 1,
                title        => $title,
            },
            ;
    }
};

1;
