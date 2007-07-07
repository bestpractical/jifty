use strict;
use warnings;

package Jifty::Plugin::Authentication::Facebook::Mixin::Model::User;
use Jifty::DBI::Schema;
use base 'Jifty::DBI::Record::Plugin';

use Jifty::Plugin::Authentication::Facebook::Record schema {

    column facebook_name => 
        type is 'text';

    column facebook_uid => 
        type is 'int',
        is immutable,
        is distinct;

    column facebook_session =>
        type is 'text';

    column facebook_session_expires =>
        type is 'int';

};

=head2 set_facebook_uid INT

Sets the user's Facebook ID

=cut

sub set_facebook_uid {
    my $self = shift;
    my $id   = shift;
    $self->_set( column => 'facebook_uid', value => $id );
}

1;

