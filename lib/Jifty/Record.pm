use warnings;
use strict;

package Jifty::Record;

use Jifty::Config;

=head1 NAME

Jifty::Record - Represents a Jifty object that lives in the database.

=head1 DESCRIPTION

C<Jifty::Record> is a kind of L<Jifty::Object> that has a database
representation; that is, it is also a L<Jifty::DBI::Record> as well.

=cut

use base qw(Jifty::Object Jifty::DBI::Record Class::Accessor::Fast);
__PACKAGE__->mk_accessors('_is_readable');

sub _init {
    my $self = shift;
    my %args = (@_);
    $self->_get_current_user(%args);
    
    $self->SUPER::_init(@_);

}

=head1 METHODS

=cut

=head2 create PARAMHASH

C<create> can be called as either a class method or an object method.

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
    my $class = shift;
    my $self;
    if ( ref($class) ) {
        ( $self, $class ) = ( $class, undef );
    } else {
        $self = $class->new();
    }

    my %attribs = @_;

    unless ( $self->check_create_rights(@_) ) {
        $self->log->error( $self->current_user->id . " tried to create a ",
            ref $self, " without permission" );
        wantarray ? return ( 0, _('Permission denied') ) : return (0);
    }

    foreach my $key ( keys %attribs ) {
        $attribs{$key} = $self->run_canonicalization_for_column(
            column => $key,
            value  => $attribs{$key}
        );
    }
    foreach my $key ( keys %attribs ) {
        my $attr = $attribs{$key};
        my ( $val, $msg ) = $self->run_validation_for_column(
            column => $key,
            value  => $attribs{$key}
        );
        if ( not $val ) {
            $self->log->error("There was a validation error for $key");
            if ($class) {
                return ($self);
            } else {
                return ( $val, $msg );
            }
        }

        # remove blank values. We'd rather have nulls
        if ( exists $attribs{$key}
            and ( !defined $attr || ( not ref($attr) and $attr eq '' ) ) )
        {
            delete $attribs{$key};
        }
    }

    my $msg = $self->SUPER::create(%attribs);
    if ( ref($msg) ) {

        # It's a Class::ReturnValue
        return $msg;
    }
    my ( $id, $status ) = $msg;
    $self->load_by_cols( id => $id ) if ($id);
    if ($class) {
        return $self;
    } else {
        return wantarray ? ( $id, $status ) : $id;
    }
}

=head2 id

Returns the record id value.
This routine short-circuits a much heavier call up through Jifty::DBI

=cut

sub _primary_key { 'id' }
sub id { $_[0]->{'values'}->{'id'} }


=head2 load_or_create

C<load_or_create> can be called as either a class method or an object method.
It attempts to load a record with the named parameters passed in.  If it
can't do so, it creates a new record.

=cut

sub load_or_create {
    my $class = shift;
    my $self;
    if (ref($class)) {
       ($self,$class) = ($class,undef); 
    } else {
        $self = $class->new();
    }

    my %args = (@_);

    my ( $id, $msg ) = $self->load_by_cols(%args);
    unless ( $self->id ) {
        return $self->create(%args);
    }

    return ($id,$msg);
}


=head2 current_user_can RIGHT [ATTRIBUTES]

Should return true if the current user (C<< $self->current_user >>) is
allowed to do I<RIGHT>.  Possible values for I<RIGHT> are:

=over

=item create

Called just before an object's C<create> method is called, as well as
before parameter validation.  ATTRIBUTES is the attributes that
the object is trying to be created with, as the attributes aren't on
the object yet to be inspected.

=item read

Called before any attribute is accessed on the object.
ATTRIBUTES is a hash with a single key C<column> and a single
value, the name of the column being queried.

=item update

Called before any attribute is changed on the object.
ATTRIBUTES is a hash of the arguments passed to _set.



=item delete

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
    
    if (Jifty->config->framework('SkipAccessControl')) {
	return 1;	
    }


    if (   $self->current_user->is_bootstrap_user
        or $self->current_user->is_superuser )
    {
        return (1);
    }

    
    if ($self->can('delegate_current_user_can')) {
        return $self->delegate_current_user_can($right, @_); 
    }

    unless ( $self->current_user->isa( 'Jifty::CurrentUser' ) ) {
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

Passes C<column> as a named parameter for the column the user is checking rights on.

=cut

sub check_read_rights {
    my $self = shift;
    return (1) if $self->_is_readable;
    return $self->current_user_can( 'read', column => shift );
}

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
        return (0, _('Permission denied'));
    }
    $self->SUPER::_set(@_);
}

    
sub _value {
    my $self = shift;
    my $column = shift;

    unless ($self->check_read_rights( $column => @_ )) {
        return (undef);
    }
    my $value = $self->SUPER::_value( $column => @_ );
    return $value if ref $value or $self->column($column)->type eq 'blob';

    Encode::_utf8_on($value) if defined $value;
    $value;
}


=head2 as_superuser

Returns a copy of this object with the current_user set to the
superuser. This is a convenient way to duck around ACLs if you have
code that needs to for some reason or another.

=cut

sub as_superuser {
    my $self = shift;

    my $clone = $self->new(current_user => $self->current_user->superuser);
    $clone->load($self->id);
    return $clone;
}


=head2 _collection_value METHOD

A method ripped from the pages of Jifty::DBI::Record 
so we could change the invocation method of the collection generator to
add a current_user argument.

=cut

sub _collection_value {
    my $self = shift;

    my $method_name = shift;
    return unless defined $method_name;

    my $column    = $self->column($method_name);
    my $classname = $column->refers_to();

    return undef unless $classname;
    return unless $classname->isa( 'Jifty::DBI::Collection' );

    if ( my $prefetched_collection = $self->_prefetched_collection($method_name)) {
        return $prefetched_collection;
    }

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
            return(0, _('Permission denied'));
        }
    $self->SUPER::delete(@_); 
}

=head2 _brief_description

When displaying a list of records, Jifty can display a friendly value 
rather than the column's unique id.  Out of the box, Jifty always
tries to display the 'name' field from the record. You can override this
method to return the name of a method on your record class which will
return a nice short human readable description for this record.

=cut

sub _brief_description {'name'}

=head2 _to_record

This is the Jifty::DBI function that is called when you fetch a value which C<REFERENCES> a
Record class.  The only change from the Jifty::DBI code is the arguments to C<new>.

=cut

sub _to_record {
    my $self  = shift;
    my $column_name = shift;
    my $value = shift;

    my $column = $self->column($column_name);
    my $classname = $column->refers_to();

    return undef unless $classname;
    return unless $classname->isa( 'Jifty::Record' );

    # XXX TODO FIXME we need to figure out the right way to call new here
    # perhaps the handle should have an initiializer for records/collections
    my $object = $classname->new(current_user => $self->current_user);
    $object->load_by_cols(( $column->by || 'id')  => $value) if ($value);
    # XXX: an attribute or hook to let model class declare implicit
    # readable refers_to columns.  $object->_is_readable(1) if $column->blah;
    return $object;
}

=head2 cache_key_prefix

Returns a unique key for this application for the Memcached cache.
This should be global within a given Jifty application instance.

=cut


sub cache_key_prefix {
    Jifty->config->framework('Database')->{'Database'};
}

sub _cache_config {
    {   'cache_p'       => 1,
        'cache_for_sec' => 60,
    };
}

=head2 since
 
By default, all models exist since C<undef>, the ur-time when the application was created. Please override it for your model class.
 
=cut
 


=head2 printable_table_schema

When called, this method will generate the SQL schema for the current version of this 
class and return it as a scalar, suitable for printing or execution in your database's command line.

=cut


sub printable_table_schema {
    my $class = shift;

    my $schema_gen = $class->_make_schema();
    return $schema_gen->create_table_sql_text;
}

=head2 create_table_in_db

When called, this method will generate the SQL schema for the current version of this 
class and insert it into the application's currently open database.

=cut

sub create_table_in_db {
    my $class = shift;

    my $schema_gen = $class->_make_schema();

    # Run all CREATE commands
    for my $statement ( $schema_gen->create_table_sql_statements ) {
        my $ret = Jifty->handle->simple_query($statement);
        $ret or die "error creating table $class: " . $ret->error_message;
    }

}

sub _make_schema { 
    my $class = shift;

    my $schema_gen = Jifty::DBI::SchemaGenerator->new( Jifty->handle )
        or die "Can't make Jifty::DBI::SchemaGenerator";
    my $ret = $schema_gen->add_model( $class->new );
    $ret or die "couldn't add model $class: " . $ret->error_message;

    return $schema_gen;
}

=head2 add_column_sql column_name

Returns the SQL statement neccessary to add C<column_name> to this class's representation in the database

=cut

sub add_column_sql {
    my $self        = shift;
    my $column_name = shift;

    my $col        = $self->column($column_name);
    my $definition = $self->_make_schema()->column_definition_sql($self->table => $col->name);
    return "ALTER TABLE " . $self->table . " ADD COLUMN " . $definition;
}

=head2 drop_column_sql column_name

Returns the SQL statement neccessary to remove C<column_name> from this class's representation in the database

=cut

sub drop_column_sql {
    my $self        = shift;
    my $column_name = shift;

    my $col = $self->column($column_name);
    return "ALTER TABLE " . $self->table . " DROP COLUMN " . $col->name;
}

=head2 schema_version

This method is used by L<Jifty::DBI::Record> to determine which schema version is in use. It returns the current database version stored in the configuration.

Jifty's notion of the schema version is currently broken into two:

=over

=item 1.

The Jifty version is the first. In the case of models defined by Jifty itself, these use the version found in C<$Jifty::VERSION>.

=item 2.

Any model defined by your application use the database version declared in the configuration. In F<etc/config.yml>, this is lcoated at:

  framework:
    Database:
      Version: 0.0.1

=back

A model is considered to be defined by Jifty if it the package name starts with "Jifty::". Otherwise, it is assumed to be an application model.

=cut

sub schema_version {
    my $class = shift;
    
    # Return the Jifty schema version
    if ($class =~ /^Jifty::Model::/) {
        return $Jifty::VERSION;
    }

    # TODO need to consider Jifty plugin versions?

    # Return the application schema version
    else {
        my $config = Jifty->config();
        return $config->framework('Database')->{'Version'};
    }
}

1;

