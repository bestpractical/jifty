package TestApp::View::base;
use Jifty::View::Declare -base;

template 'list_ht' => sub {
    my $self = shift;
    outs("/base/list=$self");
    for (0..1) {
	$self->has_template('view')->();
    }
};

template 'list_s' => sub {
    my $self = shift;
    outs("/base/list=$self");
    for (0..1) {
	show('view');
    }
};

template 'list_rg' => sub {
    my $self = shift;
    outs("/base/list=$self");
    for (0..1) {
	render_region('view-'.$_, path => 'view');
    }
};

template 'view' => sub {
    my $self = shift;
    outs("/base/view=$self");
};

1;
