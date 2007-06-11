package Yada::View;
use Jifty::View::Declare -base;

template 'index.html' => page {
    my $self = shift;
    title { _('Yada!') };

    form {
	render_region(name => 'list', path => '/todo/list');
    }
};

require Yada::View::Todo;
alias Yada::View::Todo under '/todo';


1;
