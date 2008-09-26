package TestApp::Bulk::Action::BulkUpdateThingy;
use Jifty::Action::Record::Bulk;
use base 'Jifty::Action::Record::Bulk';

use constant record_class => 'TestApp::Bulk::Model::Thingy';

__PACKAGE__->add_action('TestApp::Bulk::Action::DeleteThingy' => { trigger => 'delete', final => 1 });
__PACKAGE__->add_action('TestApp::Bulk::Action::UpdateThingy');


use Jifty::Param::Schema;
use Jifty::Action schema {

param delete => label is 'Delete',
    sort_order is -1,
    render as 'checkbox';

};

1;
