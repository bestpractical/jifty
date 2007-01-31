use strict;
use warnings;

package Jifty::Plugin::ModelBuilder::Dispatcher;
use Jifty::Dispatcher -base;

# Turn on the ModelClass actions
before '**' => run {
    my $current_user = Jifty->web->current_user;
    if ($current_user->is_superuser || $current_user->is_bootstrap_user) {
        Jifty->api->allow(qw/
            Jifty::Action::CreateModelClass
            Jifty::Action::UpdateModelClass
            Jifty::Action::DeleteModelClass
            Jifty::Action::SearchModelClass

            Jifty::Action::CreateModelClassColumn
            Jifty::Action::UpdateModelClassColumn
            Jifty::Action::DeleteModelClassColumn
            Jifty::Action::SearchModelClassColumn
        /);
    }
};

1;
