use strict;
use warnings;

package TestApp::Plugin::OAuth::Model::Favorite;
use Jifty::DBI::Schema;

use TestApp::Plugin::OAuth::Record schema {
    column 'owner' =>
        refers_to TestApp::Plugin::OAuth::Model::User;
    column 'thing' =>
        type is 'text';
};

# you only create favorites for yourself
sub before_create {
    my $self = shift;
    my $args = shift;

    $args->{owner} = Jifty->web->current_user->user_object;

    return 1;
}

sub current_user_can {
    my $self  = shift;
    my $right = shift;

    # all can read
    return 1 if $right eq 'read';

    # logged in users can create
    return Jifty->web->current_user->user_object if $right eq 'create';

    # only the owner may update his favorites
    return 0 unless Jifty->web->current_user->id == $self->owner->id;

    # none can delete
    return 0 if $right eq 'delete';

    # oauthed can update, non-oauthed can't
    return !Jifty->web->current_user->is_oauthed if $right eq 'update';

    die "Favorite->current_user_can($right) check fell through";
}

1;

