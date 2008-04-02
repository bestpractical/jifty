use strict;
use warnings;

package TestApp::Plugin::Comments::View;
use Jifty::View::Declare -base;

template 'post' => page {
    { title is 'New Post' }

    form {
        my $post_blog = new_action class => 'CreateBlogPost';
        render_action $post_blog;
        form_submit label => _('Post'), submit => $post_blog;
    };
};

template 'view' => page {
    my $blog = get 'blog';

    { title is $blog->title }

    p { _('By %1', $blog->author) };

    p { $blog->body };

    hr { };

    render_region
        name      => 'comments',
        path      => '/__comment/list',
        arguments => {
            collapsed    => 1,
            parent_class => Jifty->app_class('Model', 'BlogPost'),
            parent_id    => $blog->id,
        },
        ;
};

1;
