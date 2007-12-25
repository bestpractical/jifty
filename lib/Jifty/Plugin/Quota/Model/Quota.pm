use strict;
use warnings;

=head1 NAME

BTDT::Model::Quota

=head1 DESCRIPTION

Generic quotas for Jifty model objects.

=cut

package Jifty::Plugin::Quota::Model::Quota;
use Jifty::DBI::Schema;

use Jifty::Record schema {
    column object_id =>
        type is 'integer',
        is mandatory;
    
    column object_class =>
        type is 'text',
        is mandatory;

    column type =>
        type is 'text',
        is mandatory,
        label is 'Type';

    column cap =>
        type is 'integer',
        is mandatory,
        label is 'Cap (limit)';

    column usage =>
        type is 'integer',
        is mandatory,
        default is 0,
        label is 'Usage';
};

=head2 create PARAMHASH

=cut

sub create {
    my $self = shift;
    my %args = @_;

    if ( not defined $args{cap} ) {
        my $plugin = Jifty->find_plugin('Jifty::Plugin::Quota');
        $args{cap} = $plugin->default_cap( $args{type}, $args{object_class} );
    }

    $args{usage} = 0
        if not defined $args{usage};

    # XXX TODO: This should be in the schema, but we can't do that at the moment
    my $check = Jifty::Plugin::Quota::Model::Quota->new;
    $check->load_by_cols(
        object_id    => $args{object_id},
        object_class => $args{object_class},
        type         => $args{type}
    );
    return ( undef, "Already a quota for that object." ) if $check->id;

    return $self->SUPER::create( %args );
}

=head2 create_from_object OBJECT [PARAMHASH]

Conveniently creates a quota record using a model OBJECT and an optional
extra paramhash.

=cut

sub create_from_object {
    my $self    = shift;
    my $object  = shift;
    return $self->create( ($self->_object_attrs($object)), @_ );
}

=head2 load_by_object OBJECT [PARAMHASH]

Conveniently loads a quota record using a model OBJECT and an optional
extra paramhash.

=cut

sub load_by_object {
    my $self    = shift;
    my $object  = shift;
    return $self->load_by_cols( ($self->_object_attrs($object)), @_ );
}

sub _object_attrs {
    my $self   = shift;
    my $object = shift;
    my $class  = ref $object;
    $class =~ s/^.+::(\w+)$/$1/;
    return ( object_id => $object->id, object_class => $class );
}

=head2 object

Returns the object regulated by this quota.

=cut

sub object {
    my $self   = shift;
    my $class  = Jifty->app_class( 'Model', $self->__value('object_class') );
    my $object = $class->new( current_user => $self->current_user );
    $object->load( $self->__value('object_id') );
    return $object;
}

=head2 usage_ok INTEGER

Checks if adding INTEGER to the current I<usage> will exceed I<cap>.

Returns true or false.

=cut

sub usage_ok {
    my $self = shift;
    my $more = shift;
    return (($self->__value('usage') + $more) <= $self->__value('cap')) ? 1 : 0;
}

=head2 add_usage INTEGER

Adds INTEGER to I<usage> if there is enough quota left.

Returns true on success, false on failure.

=cut

sub add_usage {
    my $self  = shift;
    my $usage = shift;
    
    $usage =~ s/\D//g;

    if ( $self->usage_ok( $usage ) ) {
        $self->__set(
            column => 'usage',
            value  => 'usage + '.$usage,
            is_sql_function => 1
        );
        return 1;
    }
    return 0;
}

=head2 subtract_usage INTEGER

Subtracts INTEGER from I<usage>.

=cut

sub subtract_usage {
    my $self  = shift;
    my $usage = shift;
    
    $usage =~ s/\D//g;

    $self->__set(
        column => 'usage',
        value  => 'usage - '.$usage,
        is_sql_function => 1
    );
}

=head2 current_user_can

If current user can read the referenced object, then they can read the quotas.
No one can created, update, or delete quotas unless they are a superuser.

=cut

sub current_user_can {
    my $self   = shift;
    my $right  = shift;
    return 1 if $right eq 'read' and $self->object->current_user_can( $right );
    return 1 if $self->current_user->is_superuser;
    return $self->SUPER::current_user_can( $right, @_ );
}

1;

