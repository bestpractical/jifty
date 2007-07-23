package Yada::View;
use Jifty::View::Declare -base;

template 'index.html' => page {
    my $self = shift;
    title { _('Yada!') };

    form {
	render_region(name => 'list', path => '/todo/list');
    }
};

use Jifty::View::Declare::CRUD;
for (qw/todo/) {
    Jifty::View::Declare::CRUD->mount_view($_);
}

1;
