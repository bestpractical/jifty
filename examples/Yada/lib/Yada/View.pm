package Yada::View;
use Jifty::View::Declare -base;

use Jifty::View::Declare::CRUD;
for (qw/todo/) {
    Jifty::View::Declare::CRUD->mount_view($_);
}

template 'index.html' => page {
    my $self = shift;
    title { _('Yada!') };

    hyperlink(label => 'clear',
	      onclick => [{region => 'test_region',
			   replace_with => '__jifty/empty',
			  }]);

    render_region(
        name => 'test_region',
        path => '/__jifty/empty'
    );



    form {
	set(item_path => '/todo/view_brief');
	render_region(name => 'list', path => '/todo/list');
    }
};

1;
