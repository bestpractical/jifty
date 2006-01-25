use warnings;
use strict;

package Jifty::Record;

=head1 NAME

Jifty::Record - Represents a Jifty object that lives in the database.

=head1 DESCRIPTION

C<Jifty::Record> is a kind of L<Jifty::Object> that has a database
representation; that is, it is also a L<Jifty::DBI::Record> as well.

=cut

use base qw/Jifty::Object/;
use base qw/Jifty::DBI::Record::Cachable/;

sub _init {
    my $self = shift;
    my %args = (@_);
     $self->_get_current_user(%args);
    
    $self->SUPER::_init(@_);

}

=head1 METHODS

=cut

=head2 create PARAMHASH


Takes an array of key-value pairs and inserts a new row into the database representing
this object.

Override's L<Jifty::DBI::Record> in these ways:

=over 4

=item Remove C<id> values unless they are truly numeric

=item Automatically load by id after create

=item actually stop creating the new record if a field fails to validate.

=back

=cut 

sub create {
    my $self    = shift;
    my %attribs = @_;
    
    unless ($self->check_create_rights(@_)) {
        $self->log->error($self->current_user->id. " tried to create a ", ref $self, " without permission");
        wantarray ? return (0, 'Permission denied') : return(0);
    }


    foreach my $key ( keys %attribs ) {
        my $method = "validate_$key";
        next unless $self->can($method);
        my ($val, $msg ) = $self->$method( $attribs{$key} );
        unless ($val) {
            $self->log->error("There was a validation error for $key");
            return ($val, $msg);
        }
        # remove blank values. We'd rather have nulls
        if (exists $attribs{$key} and (not defined $attribs{$key} or $attribs{$key} eq "")) {
            delete $attribs{$key};
        }
    }

    my $id = $self->SUPER::create(%attribs);
    $self->load_by_cols(id => $id) if ($id);
    return wantarray  ? ($id, "Record created") : $id;
}


=head2 load_or_create

Attempts to load a record with the named parameters passed in.  If it
can't do so, it creates a new record.

=cut

sub load_or_create {
    my $self = shift;
    my %args = (@_);

    my ( $id, $msg ) = $self->load_by_cols(%args);
    unless ( $self->id ) {
        return $self->create(%args);
    }

    return ($id,$msg);
}


=head2 current_user_can RIGHT [, ATTRIBUTES]

Should return true if the current user (C<$self->current_user>) is
allowed to do I<RIGHT>.  Possible values for I<RIGHT> are:

=over

=item create

Called just before an object's C<create> method is called, as well as
before parameter validation.  It is also passed the attributes that
the object is trying to be created with, as the attributes aren't on
the object yet to be inspected.

=item read

Called before any attribute is accessed on the object.

=item edit

Called before any attribute is changed on the object.

=item admin

Called before the object is deleted.

=back

The default implementation returns true if the current user is a
superuser or a boostrap user.  If the user is looking to delegate the
access control decision to another object (by creating a
C<delegate_current_user_can> subroutine), it hands off to that
routine.  Otherwise, it returns false.

=cut

sub current_user_can {
    my $self  = shift;
    my $right = shift;

    if (   $self->current_user->is_bootstrap_user
        or $self->current_user->is_superuser )
    {
        return (1);
    }

    
    if ($self->can('delegate_current_user_can')) {
        return $self->delegate_current_user_can($right, @_); 
    }

    unless ( UNIVERSAL::isa( $self->current_user, 'Jifty::CurrentUser' ) ) {
        $self->log->error(
            "Hm. called to authenticate without a currentuser - "
                . $self->current_user );
        return (0);
    }
    return (0);

}

=head2 check_create_rights ATTRIBUTES

Internal helper to call L</current_user_can> with C<create>.

=cut

sub check_create_rights { return shift->current_user_can('create', @_) }


=head2 check_read_rights

Internal helper to call L</current_user_can> with C<read>.

Passed C<column> as a named parameter for the column the user is checking rights
on.

=cut

sub check_read_rights { return shift->current_user_can('read', column => shift) }


=head2 check_update_rights

Internal helper to call L</current_user_can> with C<update>.

=cut

sub check_update_rights { return shift->current_user_can('update', @_) } 


=head2 check_delete_rights

Internal helper to call L</current_user_can> with C<delete>.

=cut

sub check_delete_rights { return shift->current_user_can('delete', @_) }


sub _set {
    my $self = shift;

    unless ($self->check_update_rights(@_)) {
        Jifty->log->logcluck("Permission denied");
        return (0, 'Permission denied');
    }
    $self->SUPER::_set(@_);
}

    
sub _value {
    my $self = shift;

    unless ($self->check_read_rights(@_)) {
        return (undef);
    }
    my $value = $self->SUPER::_value(@_);
    utf8::upgrade($value) if defined $value;
    $value;
}


=head2 _collection_value METHOD

A method ripped from the pages of Jifty::DBI::Record 
so we could change the invocation method of hte collection generator to
add a current_user argument.

=cut

sub _collection_value {
    my $self = shift;

    my $method_name = shift;
    return unless defined $method_name;

    my $column    = $self->column($method_name);
    my $classname = $column->refers_to();

    return undef unless $classname;
    return unless UNIVERSAL::isa( $classname, 'Jifty::DBI::Collection' );


    my $coll = $classname->new( current_user => $self->current_user );
    if ($column->by and $self->id) { 
            $coll->limit( column => $column->by(), value => $self->id );
    }
    return $coll;
}

=head2 delete PARAMHASH

Overrides L<Jifty::DBI::Record> to check the delete ACL.

=cut

sub delete {
    my $self = shift;
    unless ($self->check_delete_rights(@_)) {
            Jifty->log->logcluck("Permission denied");
            return(0, 'Permission denied');
        }
    $self->SUPER::delete(@_); 
}

=head2 _to_record

This is the SB function that is called when you fetch a value which C<REFERENCES> a
Record class.  The only change from the SB code is the arguments to C<new>.

=cut

sub _to_record {
    my $self  = shift;
    my $column_name = shift;
    my $value = shift;

    my $column = $self->column($column_name);
    my $classname = $column->refers_to();

    return unless defined $value;
    return undef unless $classname;
    return unless UNIVERSAL::isa( $classname, 'Jifty::DBI::Record' );

    # XXX TODO FIXME we need to figure out the right way to call new here
    # perhaps the handle should have an initiializer for records/collections
    my $object = $classname->new();
    $object->load_by_cols(( $column->by || 'id')  => $value);
    return $object;
}

1;

