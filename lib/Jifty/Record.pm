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

use base qw( Jifty::Object Jifty::DBI::Record);

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

Takes an array of key-value pairs and inserts a new row into the
database representing this object.

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
            value  => $attribs{$key},
            extra  => [\%attribs, { for => 'create' }],
        );
    }
    foreach my $key ( keys %attribs ) {
        my $attr = $attribs{$key};
        my ( $val, $msg ) = $self->run_validation_for_column(
            column => $key,
            value  => $attribs{$key},
            extra  => [\%attribs, { for => 'create' }],
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

sub _primary_key {'id'}
sub id           { $_[0]->{'values'}->{'id'} }

=head2 load_or_create

C<load_or_create> can be called as either a class method or an object method.
It attempts to load a record with the named parameters passed in.  If it
can't do so, it creates a new record.

=cut

sub load_or_create {
    my $class = shift;
    my $self;
    if ( ref($class) ) {
        ( $self, $class ) = ( $class, undef );
    } else {
        $self = $class->new();
    }

    my %args = (@_);

    my ( $id, $msg ) = $self->load_by_cols(%args);
    unless ( $self->id ) {
        return $self->create(%args);
    }

    return ( $id, $msg );
}

=head2 as_create_action PARAMHASH

Returns the L<Jifty::Action::Record::Create> action for this model
class.

The PARAMHASH allows you to add additional parameters to pass to
L<Jifty::Web/new_action>.

=cut

sub _action_from_record {
    my $self  = shift;
    my $verb  = shift;
    my $class = ref $self || $self;
    $class =~ s/::Model::/::Action::$verb/;
    return $class;
}

sub as_create_action {
    my $self         = shift;
    my $action_class = $self->_action_from_record('Create');
    return Jifty->web->new_action( class => $action_class, @_ );
}

=head2 as_update_action PARAMHASH

Returns the L<Jifty::Action::Record::Update> action for this model
class. The current record is passed to the constructor.

The PARAMHASH allows you to add additional parameters to pass to
L<Jifty::Web/new_action>.

=cut

sub as_update_action {
    my $self         = shift;
    my $action_class = $self->_action_from_record('Update');
    return Jifty->web->new_action(
        class  => $action_class,
        record => $self,
        @_,
    );
}

=head2 as_delete_action PARAMHASH

Returns the L<Jifty::Action::Record::Delete> action for this model
class. The current record is passed to the constructor.

The PARAMHASH allows you to add additional parameters to pass to
L<Jifty::Web/new_action>.

=cut

sub as_delete_action {
    my $self         = shift;
    my $action_class = $self->_action_from_record('Delete');
    return Jifty->web->new_action(
        class  => $action_class,
        record => $self,
        @_,
    );
}

=head2 as_search_action PARAMHASH

Returns the L<Jifty::Action::Record::Search> action for this model
class.

The PARAMHASH allows you to add additional parameters to pass to
L<Jifty::Web/new_action>.

=cut

sub as_search_action {
    my $self         = shift;
    my $action_class = $self->_action_from_record('Search');
    return Jifty->web->new_action(
        class => $action_class,
        @_,
    );
}

=head2 _guess_table_name

Guesses a table name based on the class's last part. In addition to
the work performed in L<Jifty::DBI::Record>, this method also prefixes
the table name with the plugin table prefix, if the model belongs to a
plugin.

=cut

sub _guess_table_name {
    my $self  = shift;
    my $table = $self->SUPER::_guess_table_name;

    # Add plugin table prefix if a plugin model
    my $class = ref($self) ? ref($self) : $self;
    my $app_plugin_root = Jifty->app_class({require => 0}, 'Plugin');
    if ( $class =~ /^(?:Jifty::Plugin::|$app_plugin_root)/ ) {

        # Guess the plugin class name
        my $plugin_class = $class;
        $plugin_class =~ s/::Model::(.*)$//;

        # Try to load that plugin's configuration
        my ($plugin) = grep { ref $_ eq $plugin_class } Jifty->plugins;

        # Add the prefix if found
        if ( defined $plugin ) {
            $table = $plugin->table_prefix . $table;
        }

        # Uh oh. Warn, but try to keep going.
        else {
            warn
                "Model $class looks like a plugin model, but $plugin_class could not be found.";
        }
    }

    return $table;
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

Models wishing to customize authorization checks should override this
method. You can do so like this:

  sub current_user_can {
      my ($self, $right, %args) = @_;

      # Make any custom checks that return 1 to allow or return 0 to deny...
      
      # Fallback upon the default implementation to handle the
      # SkipAccessControl configuration setting, superuser, bootstrap,
      # delegation, and the before_access hook
      return $self->SUPER::current_user_can($right, %args);
  }

If you are sure you don't want your model to fallback using the
default implementation, you can replace the last line with whatever
fallback policy required.

=head3 Authorization steps

The default implementation proceeds as follows:

=over

=item 1.

If the C<SkipAccessControl> setting is set to a true value in the
framework configuration section of F<etc/config.yml>,
C<current_user_can> always returns true.

=item 2.

The method first attempts to call the C<before_access> hooks to check
for any allow or denial. See L</The before_access hook>.

=item 3.

Next, the default implementation returns true if the current user is a
superuser or a boostrap user.

=item 4.

Then, if the model can perform delegation, usually by using
L<Jifty::RightsFrom>, the access control decision is deferred to
another object (via the C<delegate_current_user_can> subroutine).

=item 5.

Otherwise, it returns false.

=back

=head3 The before_access hook

This implementation may make use of a trigger called C<before_access>
to make the decision. A new handler can be added to the trigger point
by calling C<add_handler>:

  $record->add_trigger(
      name => 'before_access',
      code => \&before_access,
      abortable => 1,
  );

The C<before_access> handler will be passed the same arguments that
were used to call C<current_user_can>, including the current record
object, the operation being checked, and any arguments being passed to
the operation.

The C<before_access> handler should return one of three strings:
C<'deny'>, C<'allow'>, or C<'ignore'>. The C<current_user_can>
implementation reacts as follows to these results:

=over

=item 1.

If a handler is abortable and aborts by returning a false value (such
as C<undef>), C<current_user_can> returns false.

=item 2.

If any handler returns 'deny', C<current_user_can> returns false.

=item 3.

If any handler returns 'allow' and no handler returns 'deny',
C<current_user_can> returns true.

=item 4.

In all other cases, the results of the handlers are ignored and
C<current_user_can> proceeds to check using superuser, bootstrap, and
delegation.

=back

=cut

sub current_user_can {
    my $self  = shift;
    my $right = shift;

    # Turn off access control for the whole application
    if ( Jifty->config->framework('SkipAccessControl') ) {
        return 1;
    }

    my $hook_status = $self->call_trigger( before_access => $right, @_ );

    # If not aborted...
    if ( defined $hook_status ) {

        # Compile the handler results
        my %results;
        $results{ $_->[0] }++ for ( @{ $self->last_trigger_results } );

        # Deny always takes precedent
        if ( $results{deny} ) {
            return 0;
        }

        # Then allow...
        elsif ( $results{allow} ) {
            return 1;
        }

        # Otherwise, no instruction from the handlers, move along...
    }

    # Abort! Return false for safety if the hook exploded
    else {
        return 0;
    }


    Carp::confess "No current user" unless ( $self->current_user );
    if (   $self->current_user->is_bootstrap_user
        or $self->current_user->is_superuser )
    {
        return (1);
    }

    if ( $self->can('delegate_current_user_can') ) {
        return $self->delegate_current_user_can( $right, @_ );
    }

    unless ( $self->current_user->isa('Jifty::CurrentUser') ) {
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

sub check_create_rights { return shift->current_user_can( 'create', @_ ) }

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

sub check_update_rights { return shift->current_user_can( 'update', @_ ) }

=head2 check_delete_rights

Internal helper to call L</current_user_can> with C<delete>.

=cut

sub check_delete_rights { return shift->current_user_can( 'delete', @_ ) }

sub _set {
    my $self = shift;

    unless ( $self->check_update_rights(@_) ) {
        return ( 0, _('Permission denied') );
    }
    $self->SUPER::_set(@_);
}

sub _value {
    my $self   = shift;
    my $column = shift;

    unless ( $self->check_read_rights( $column => @_ ) ) {
        return (undef);
    }
    my $value = $self->SUPER::_value( $column => @_ );
    return $value if ref $value or $self->column($column)->type eq 'blob';

    Encode::_utf8_on($value) if defined $value;
    $value;
}

=head2 as_user CurrentUser

Returns a copy of this object with the current_user set to the given
current_user. This is a way to act on behalf of a particular user (perhaps the
owner of the object)

=cut

sub as_user {
    my $self = shift;
    my $user = shift;

    my $clone = $self->new( current_user => $user );
    $clone->load( $self->id );
    return $clone;
}

=head2 as_superuser

Returns a copy of this object with the current_user set to the
superuser. This is a convenient way to duck around ACLs if you have
code that needs to for some reason or another.

=cut

sub as_superuser {
    my $self = shift;
    return $self->as_user( $self->current_user->superuser );
}

=head2 delete PARAMHASH

Overrides L<Jifty::DBI::Record> to check the delete ACL.

=cut

sub delete {
    my $self = shift;
    unless ( $self->check_delete_rights(@_) ) {
        $self->log->logcluck("Permission denied");
        return ( 0, _('Permission denied') );
    }
    $self->SUPER::delete(@_);
}

=head2 brief_description

Display the friendly name of the record according to _brief_description.

=cut

sub brief_description {
    my $self   = shift;
    my $method = $self->_brief_description;
    return $self->$method;
}

=head2 _brief_description

When displaying a list of records, Jifty can display a friendly value
rather than the column's unique id.  Out of the box, Jifty always
tries to display the 'name' field from the record. You can override
this method to return the name of a method on your record class which
will return a nice short human readable description for this record.

=cut

sub _brief_description {'name'}

=head2 null_reference

By default, L<Jifty::DBI::Record> returns C<undef> on non-existant
related fields; Jifty prefers to get back an object with an undef id.

=cut

sub null_reference { 0 }

=head2 _new_collection_args

Overrides the default arguments which this collection passes to new
collections, to pass the C<current_user>.

=cut

sub _new_collection_args {
    my $self = shift;
    return ( current_user => $self->current_user );
}

=head2 _new_record_args

Overrides the default arguments which this collection passes to new
records, to pass the C<current_user>.

=cut

sub _new_record_args {
    my $self = shift;
    return ( current_user => $self->current_user );
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

By default, all models exist since C<undef>, the ur-time when the
application was created. Please override it for your model class.

=cut

=head2 printable_table_schema

When called, this method will generate the SQL schema for the current
version of this class and return it as a scalar, suitable for printing
or execution in your database's command line.

=cut

sub printable_table_schema {
    my $class = shift;

    my $schema_gen = $class->_make_schema();
    return $schema_gen->create_table_sql_text;
}


=head2 table_schema_statements

When called, this method will generate the SQL schema statements
for the current version of this class and return it as array.

=cut

sub table_schema_statements {
    my $class = shift;

    my $schema_gen = $class->_make_schema();
    return $schema_gen->create_table_sql_statements;
}




=head2 create_table_in_db

When called, this method will generate the SQL schema for the current
version of this class and insert it into the application's currently
open database.

=cut

sub create_table_in_db {
    my $class = shift;

    # Run all CREATE commands
    for my $statement ( $class->table_schema_statements ) {
        my $ret = Jifty->handle->simple_query($statement);
        $ret or die "error creating table $class: " . $ret->error_message;
    }

}

=head2 drop_table_in_db 

When called, this method will generate the SQL to remove this model's
table in the database and execute it in the application's currently
open database.  This method can destroy a lot of data. Be sure you
know what you're doing.


=cut

sub drop_table_in_db {
    my $self = shift;
    my $ret  = Jifty->handle->simple_query( 'DROP TABLE ' . $self->table );
    $ret or die "error removing table $self: " . $ret->error_message;
}

sub _make_schema {
    my $class = shift;

    require Jifty::DBI::SchemaGenerator;
    my $schema_gen = Jifty::DBI::SchemaGenerator->new( Jifty->handle )
        or die "Can't make Jifty::DBI::SchemaGenerator";
    my $ret = $schema_gen->add_model( $class->new );
    $ret or die "couldn't add model $class: " . $ret->error_message;

    return $schema_gen;
}

=head2 add_column_sql column_name

Returns the SQL statement necessary to add C<column_name> to this
class's representation in the database

=cut

sub add_column_sql {
    my $self        = shift;
    my $column_name = shift;

    my $col        = $self->column($column_name);
    my $definition = $self->_make_schema()
        ->column_definition_sql( $self->table => $col->name );
    return "ALTER TABLE " . $self->table . " ADD COLUMN " . $definition;
}

=head2 add_column_in_db column_name

Executes the SQL code generated by add_column_sql. Dies on failure.

=cut

sub add_column_in_db {
    my $self = shift;
    my $ret  = Jifty->handle->simple_query( $self->add_column_sql(@_) );
    $ret
        or die "error adding column "
        . $_[0]
        . " to  $self: "
        . $ret->error_message;

}

=head2 drop_column_sql column_name

Returns the SQL statement necessary to remove C<column_name> from this
class's representation in the database

=cut

sub drop_column_sql {
    my $self        = shift;
    my $column_name = shift;

    my $col = $self->column($column_name);
    return "ALTER TABLE " . $self->table . " DROP COLUMN " . $col->name;
}

=head2 drop_column_in_db column_name

Executes the SQL code generated by drop_column_sql. Dies on failure.

=cut

sub drop_column_in_db {
    my $self = shift;
    my $ret  = Jifty->handle->simple_query( $self->drop_column_sql(@_) );
    $ret
        or die "error dropping column "
        . $_[0]
        . " to  $self: "
        . $ret->error_message;

}

=head2 schema_version

This method is used by L<Jifty::DBI::Record> to determine which schema
version is in use. It returns the current database version stored in
the configuration.

Jifty's notion of the schema version is currently broken into two:

=over

=item 1.

The Jifty version is the first. In the case of models defined by Jifty
itself, these use the version found in C<$Jifty::VERSION>.

=item 2.

Any model defined by your application use the database version
declared in the configuration. In F<etc/config.yml>, this is lcoated
at:

  framework:
    Database:
      Version: 0.0.1

=back

A model is considered to be defined by Jifty if it the package name
starts with "Jifty::". Otherwise, it is assumed to be an application
model.

=cut

sub schema_version {
    my $class = shift;

    # Return the Jifty schema version
    if ( $class =~ /^Jifty::Model::/ ) {
        return $Jifty::VERSION;
    }

    # TODO need to consider Jifty plugin versions?

    # Return the application schema version
    else {
        my $config = Jifty->config();
        return $config->framework('Database')->{'Version'};
    }
}

=head2 column_serialized_as



=cut

sub column_serialized_as {
    my ($class, $column) = @_;
    my $meta = $column->attributes->{serialized} or return;
    $meta->{columns} ||= [$column->refers_to->default_serialized_as_columns]
        if $column->refers_to;
    return $meta;
}

=head2 default_serialized_as_columns

=cut

sub default_serialized_as_columns {
    my $class = shift;
    return ('id', $class->_brief_description);
}

=head2 jifty_serialize_format

This is used to create a hash reference of the object's values. Unlike
Jifty::DBI::Record->as_hash, this won't transform refers_to columns into JDBI
objects. Override this if you want to include calculated values (for use in,
say, your REST interface)

=cut

sub jifty_serialize_format {
    my $record = shift;
    my %data;

    # XXX: maybe just test ->virtual?
    for my $column (grep { $_->readable } $record->columns ) {
        next if UNIVERSAL::isa($column->refers_to,
                               'Jifty::DBI::Collection');
        next if $column->container;
        my $name = $column->aliased_as || $column->name;

        if ((my $refers_to      = $column->refers_to) &&
            (my $serialize_meta = $record->column_serialized_as($column))) {
            my $column_data = $record->$name();
            if ( $column_data && $column_data->id ) {
                $name = $serialize_meta->{name} if $serialize_meta->{name};
                $data{$name} = { map { $_ => scalar $record->$name->$_ } @{$serialize_meta->{columns} } };
            }
            else {
                $data{$name} = undef;
            }
        }
        else {
            $data{$name} = Jifty::Util->stringify($record->_value($name));
        }
    }

    return \%data;
}

=head2 autogenerate_action

Controls which of the L<Jifty::Action::Record> subclasses are
automatically set up for this model; this subroutine is passed one of
the strings C<Create>, C<Update>, C<Delete>, C<Search> or C<Execute>, and should
return a true value if that action should be autogenerated.

The default method returns 0 for all action classes if the model is
marked as L</is_private>.  It returns 0 for all actions that are not
C<Search> if the model is marked as L</is_protected>; otherwise, it
returns true.

=cut

sub autogenerate_action {
    my $class = shift;
    my($action) = @_;

    return 0 if $class->is_private;
    return 0 if $class->is_protected and $action ne "Search";

    return 1;
}

=head2 is_private

Override this method to return true to not generate any actions for
this model, and to hide it from REST introspection.

=cut

sub is_private { 0 }

=head2 is_protected

Override this method to return true to only generate Search actions
for this model.

=cut

sub is_protected { return shift->is_private }

=head2 enumerable

Controls whether autogenerated actions with columns that refer to this
class should attempt to provide a drop-down of possible values or not.
This method will be called as a class method, and defaults to true.

=cut

sub enumerable { 1 }

1;
