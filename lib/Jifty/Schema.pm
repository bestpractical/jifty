use warnings;
use strict;

package Jifty::Schema;
use base qw/Jifty::Object/;
use SQL::ReservedWords;

=head1 NAME

Jifty::Schema - generates and upgrades your application's schema

=cut

Jifty::Module::Pluggable->import(
    require     => 1,
    search_path => ["SQL::ReservedWords"],
    sub_name    => '_sql_dialects',
);

our %_SQL_RESERVED          = ();
our @_SQL_RESERVED_OVERRIDE = qw/value/;
foreach my $dialect ( 'SQL::ReservedWords', &_sql_dialects ) {
    foreach my $word ( $dialect->words ) {
        push @{ $_SQL_RESERVED{ lc($word) } }, $dialect->reserved_by($word);
    }
}

# XXX TODO: QUESTIONABLE ENGINEERING DECISION
# The SQL standard forbids columns named 'value', but just about everone on the planet
# actually supports it. Rather than going about scaremongering, we choose
# not to warn people about columns named 'value'

delete $_SQL_RESERVED{ lc($_) } for (@_SQL_RESERVED_OVERRIDE);

=head2 new

Returns a new Jifty::Schema. Takes no arguments. Will automatically figure out and initialize the models defined in the application's source.

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_init_model_list();
    return $self;

}

=head2 _init_model_list

Reads in our application class from the config file and finds all our application's models.

=head2 models

Returns a list of Models available to your application.  This includes
your Models, Collections and those that come from core Jifty and
plugins.

Unfortunately, this list does not contain any of the PubSub Models

=cut

sub _init_model_list {
    my $self = shift;

    # Plugins can have models too
    my @plugins = map { (ref $_).'::Model' } Jifty->plugins;

    # This creates a sub "models" which when called, finds packages under
    # the application's ::Model, requires them, and returns a list of their
    # names.
    Jifty::Module::Pluggable->import(
        require     => 1,
        except      => qr/\.#/,
        search_path => [ "Jifty::Model", Jifty->app_class("Model"), @plugins ],
        sub_name    => 'models',
    );
}

=head2 serialize_current_schema

Returns a serialization of the models in the app

=cut

sub serialize_current_schema {
    my $self = shift;    
   
    my @models = $self->model_classes;
    my $serialized_models = {};
    foreach my $model (@models) {
        $serialized_models->{$model->_class_name} = $model->serialize_metadata;
    }

    return $serialized_models;

}


=head2 upgrade_schema

Looks at the current schema as defined by the source code and the database and updates the database by adding, dropping, and renaming columns.

=cut

sub upgrade_schema {
    my $self = shift;


    # load the database schema version

    # hashref
    my $old_tables = $self->current_db_schema;

    # hashref
    my $new_tables = $self->new_db_schema;

    my $add_tables = {};
    my $remove_tables ={};
    my $add_columns = {};
    my $remove_columns = {};

    # diff the current schema version and the database schema version
    foreach my $table ( keys %$old_tables ) {
        unless ( $new_tables->{$table} ) {
            $remove_tables->{$table} = $old_tables->{$table};
            next;
        }

        foreach my $column ( @{ $old_tables->{$table}->columns } ) {

     # if the column isn't in the new table as well, then mark it for deletion
            unless ( $new_tables->{$table}->column($column) ) {
                push @{ $remove_columns->{$table} }, $column;
            }

        # XXX TODO: compare the column definitions and alter them if necessary

        }
    }

    foreach my $table ( keys %$new_tables ) {
        unless ( $old_tables->{$table} ) {
            $add_tables->{$table} = $new_tables->{$table};
            next;
        }

        foreach my $column ( @{ $new_tables->{$table}->columns } ) {

     # if the column isn't in the old table as well, then mark it for addition
            unless ( $old_tables->{$table}->column($column) ) {
                push @{ $add_columns->{$table} }, $column;
            }

        # XXX TODO: compare the column definitions and alter them if necessary

        }
    }

    # Run all "Rename" rules
    $self->run_upgrade_rules('before_all_renames');
    my $table_renames  = Jifty->upgrade->table_renames;
    my $column_renames = Jifty->upgrade->column_renames;
    $self->run_upgrade_rules('after_column_renames');

    $self->_add_tables($add_tables);
    $self->_add_columns($add_columns);
    $self->_drop_tables($remove_tables);
    $self->_drop_columns($remove_columns);


}


sub _add_tables {
    my $self = shift;
    my $add_tables = shift;


    # add all new tables
    $self->run_upgrade_rules('before_table_adds');
    foreach my $table ( values %$add_tables ) {
        $self->run_upgrade_rules( 'before_add_table_' . $table );
        $add_tables->{$table}->create_table_in_db();
        $self->run_upgrade_rules( 'after_add_table_' . $table );
    }
    $self->run_upgrade_rules('after_table_adds');
}


sub _add_columns {
    my $self = shift;
    my $add_columns = shift;

    $self->run_upgrade_rules('before_column_adds');
    foreach my $table ( values %$add_columns ) {
            $self->run_upgrade_rules( 'before_add_columns_to_table_' . $table );
        my @cols = @{ $add_columns->{$table} };
        foreach my $col (@cols) {
            $self->run_upgrade_rules( 'before_add_column_' . $col->name . '_to_table_' . $table );
            $add_columns->{$table}->add_column_in_db($col);
            $self->run_upgrade_rules( 'after_add_column_' . $col->name . '_to_table_' . $table );
        }
            $self->run_upgrade_rules( 'after_add_columns_to_table_' . $table );
    }
    $self->run_upgrade_rules('after_add_columns');

}


   

sub _drop_tables {
    my $self  =shift;
    my $remove_tables = shift;


    $self->run_upgrade_rules('before_drop_tables');

    foreach my $table ( values %$remove_tables ) {
        $self->run_upgrade_rules( 'before_drop_table_' . $table );
        $remove_tables->{$table}->drop_table_in_db();
        $self->run_upgrade_rules( 'after_drop_table_' . $table );
    }
    $self->run_upgrade_rules('after_drop_tables');

}

sub _drop_columns {
    my $self = shift;
    my $remove_columns = shift;

    $self->run_upgrade_rules('before_drop_columns');

    foreach my $table ( values %$remove_columns ) {
            $self->run_upgrade_rules( 'before_drop_columns_from_' . $table );
        my @cols = @{ $remove_columns->{$table} };
        foreach my $col (@cols) {
            $self->run_upgrade_rules( 'before_drop_column' . $col->name . '_from_' . $table );
            $remove_columns->{$table}->drop_column_in_db($col);
            $self->run_upgrade_rules( 'after_drop_column_' . $col->name . '_from_' . $table );
        }
            $self->run_upgrade_rules( 'after_drop_columns_from_' . $table );
    }
    $self->run_upgrade_rules('after_drop_columns');

}


=head2 run_upgrade_rules rule_name

This method runs all upgrade rules for the rule named C<rule_name>.

=cut

sub run_upgrade_rules {
    my $self = shift;
    my $rule_name = shift;

   my $upgrade_object = Jifty->app_class('Upgrade');
   $upgrade_object->call_trigger($rule_name);
}



sub _check_reserved {
    my $self  = shift;
    my $model = shift;
    my $log   = Log::Log4perl->get_logger("SchemaTool");
    foreach my $col ( $model->columns ) {
        if ( exists $_SQL_RESERVED{ lc( $col->name ) } ) {
            $log->error(
                      $model . ": "
                    . $col->name
                    . " is a reserved word in these SQL dialects: "
                    . join( ', ',
                    _classify_reserved_words( @{ $_SQL_RESERVED{ lc( $col->name ) } } ) )
            );
        }
    }
}

sub _classify_reserved_words {
    my %dbs;

    # Guess names of databases + their versions by breaking on last space,
    # e.g., "SQL Server 7" is ("SQL Server", "7"), not ("SQL", "Server 7").
    push @{ $dbs{ $_->[0] } }, $_->[1]
        for map { [ split /\s+(?!.*\s)/, $_, 2 ] } @_;
    return
        map { join " ", $_, __parenthesize_sql_variants( @{ $dbs{$_} } ) } sort keys %dbs;
}

sub __parenthesize_sql_variants {
    if ( not defined $_[0] ) { return () }
    if ( @_ == 1 )           { return $_[0] }
    return "(" . ( join ", ", @_ ) . ")";
}

=head2 connect_to_db_for_management

Returns a database handle suitable for direct manipulation.

=cut

sub connect_to_db_for_management {
    my $handle = Jifty::Handle->new();

    my $driver = Jifty->config->framework('Database')->{'Driver'};

    # Everything but the template1 database is assumed
    my %connect_args;
    $connect_args{'database'} = 'template1'
        if ( $handle->isa("Jifty::DBI::Handle::Pg") );
    $connect_args{'database'} = ''
        if ( $handle->isa("Jifty::DBI::Handle::mysql") );
    for ( 1 .. 50 ) {
        my $counter = $_;
        eval { $handle->connect(%connect_args); };
        my $err = $@;
        last if ( !$err || $err =~ /does not exist/i );
        sleep 1;
    }
    return $handle;
}


1;
