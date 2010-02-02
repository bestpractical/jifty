use strict;
use warnings;

package TestApp::Uploads::View;
use Jifty::View::Declare -base;

template 'uploads.html' => page { title => _('Test uploads') } content {
    my $self = shift;
    my $moniker = 'uploads';
    my $action  = new_action(
        class   => 'TestApp::Uploads::Action::Uploads',
        moniker => $moniker,
    );
    with( name => $moniker ), form {
        render_action($action);
        form_submit( label => _('Submit') );
    }
};

1;
