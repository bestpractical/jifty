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

under '__jifty/builder/model' => [

    on '*' => run {
        my $id = $1;

        my $model_class = Jifty::Model::ModelClass->new;

        if ($id =~ /^(\d+)$/) {
            $model_class->load($id);
        }

        else {
            $model_class->load_by_cols( name => $id );
        }

        if ($model_class->id) {
            set model_class => $model_class;
            show '/__jifty/builder/model/edit';
        }

        else {
            warn "Could not load model for id or name: $id";
        }
    },

    on '' => run {
        show '/__jifty/builder/model/list';
    },
];

1;
