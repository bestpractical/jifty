use strict;
use warnings;

package TestApp::Plugin::Comments::Dispatcher;
use Jifty::Dispatcher -base;

on 'view/#' => run {
    my $blog = TestApp::Plugin::Comments::Model::BlogPost->new;
    $blog->load($1);

    set blog => $blog;
    show 'view';
};

1;
