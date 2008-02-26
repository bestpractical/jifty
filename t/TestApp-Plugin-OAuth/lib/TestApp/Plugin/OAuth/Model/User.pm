use strict;
use warnings;

package TestApp::Plugin::OAuth::Model::User;
use Jifty::DBI::Schema;

use TestApp::Plugin::OAuth::Record schema {
    column 'tasty' =>
        type is 'boolean',
        default is 'f';
    column 'favorites' =>
        refers_to TestApp::Plugin::OAuth::Model::FavoriteCollection by 'owner';

};

use Jifty::Plugin::User::Mixin::Model::User;
use Jifty::Plugin::Authentication::Password::Mixin::Model::User;

sub current_user_can {
    my $self = shift;

    return 1 if $self->current_user->is_superuser;
    return 1 if $_[0] eq 'create';

    my $id = $self->__value('id');
    return 1 if $id == $self->current_user->id;

    $self->SUPER::current_user_can(@_);
}

1;

