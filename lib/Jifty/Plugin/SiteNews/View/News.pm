use warnings;
use strict;

package Jifty::Plugin::SiteNews::View::News;
use Jifty::View::Declare -base;
use Jifty::View::Declare::CRUD;

template 'index.html' => page {


    h1 { 'This is your site news'};
    form {
        show('list');
    }

};




template '/edit' => page {
    h1 {'foo'};
    
};


alias Jifty::View::Declare::CRUD under '.', { object_type => 'News', base_path => '/news', 
    fragment_for_list => '/news/list',
    fragment_for_view => '/news/view'

};

1;
