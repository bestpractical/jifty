package Yada::View;
use Jifty::View::Declare -base;
use strict;

use Jifty::View::Declare::CRUD;
for (qw/todo/) {
    Jifty::View::Declare::CRUD->mount_view($_);
}

template 'index.html' => page {
    my $self = shift;
    title { _('Yada!') };

    render_region('test_region');

    hyperlink(label => 'FAQ',
	      onclick => [{region => 'test_region',
			   replace_with => '_faq',
			  }]);

    form {
	set(item_path => '/todo/view_brief');
	render_region(name => 'list', path => '/todo/list');
    }
};

template '_faq' => sub :Static {
    hyperlink(label => 'close', onclick => [{replace_with => '/__jifty/empty'}]);

    div {
        attr { id => "faq" };
        h2 { _('Using Yada') }
        dl {
            dt { 'Yada Yada Yada!'}
            dd {
                span {
                    'are we nearly there yet?'
                }
	    }
	};
    }
};

template 'signup' => page {
    title is _('Sign up');
    render_region(name => 'signup_widget', path => '_signup');
};

template '_signup' => sub :Action {
    my $action = Jifty->web->new_action( class => 'Signup', moniker => 'signupnow');
    my $next = undef;
#    with ( call => $next ),
    form {
	render_param( $action => 'name' , focus => 1);
	render_param( $action => $_ ) for ( grep {$_ ne 'name'} $action->argument_names );

	form_return( label => _('Sign up'), submit => $action );
    }

};


1;
