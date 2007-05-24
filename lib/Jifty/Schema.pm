use warnings;
use strict;

package Jifty::Schema;
use base qw/Jifty::Object/;
use SQL::ReservedWords;

Jifty::Module::Pluggable->import(
    require     => 1,
    search_path => ["SQL::ReservedWords"],
    sub_name    => '_sql_dialects',
);

our %_SQL_RESERVED          = ();
our @_SQL_RESERVED_OVERRIDE = qw(value);
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



sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_init_model_list();
    return $self;

}

=head2 _init_model_list

Reads in our application class from the config file and finds all our app's models.

=cut

sub _init_model_list {

    my $self = shift;

    # This creates a sub "models" which when called, finds packages under
    # the application's ::Model, requires them, and returns a list of their
    # names.
    Jifty::Module::Pluggable->import(
        require     => 1,
        except      => qr/\.#/,
        search_path => [ "Jifty::Model", Jifty->app_class("Model") ],
        sub_name    => 'models',
    );
}


sub serialize_current_schema {
    my $self = shift;    
   
    my @models = grep {$_->isa('Jifty::Record') && $_->table }  $self->models;
    my $serialized_models = {};
    foreach my $model (@models) {
        $serialized_models->{$model} = $model->serialize_metadata;
    }
    return $serialized_models;

}


sub _store_current_schema {
    my $self = shift;
     Jifty::Model::Metadata->store( current_schema      => Jifty::YAML::Dump($self->serialize_current_schema ));
}

sub _load_stored_schema {
    my $self = shift;
     my $schema =  Jifty::YAML::Load(Jifty::Model::Metadata->load( 'current_schema'));
    return $schema;
}



sub autoupgrade_schema {
    my $self = shift;

    my ( $add_tables, $add_columns, $remove_tables, $remove_columns )
        = $self->compute_schema_diffs( $self->_load_stored_schema, $self->serialize_current_schema);


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

sub compute_schema_diffs{
    my $self = shift;

    # load the database schema version
    my $old_tables = shift;

    # hashref
    my $new_tables = shift;

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

        foreach my $column_name ( keys %{ $old_tables->{$table}->{columns} } ) {
                my $column = $old_tables->{$table}->{columns}->{$column_name};


     # if the column isn't in the new table as well, then mark it for deletion
            unless ( $new_tables->{$table}->{columns}->{$column_name} ) {
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

        foreach my $column_name ( keys %{$new_tables->{$table}->{columns}} ) {
            my $column = $new_tables->{$table}->{columns}->{$column_name};

             # if the column isn't in the old table as well, then mark it for addition
            unless ( $old_tables->{$table}->{columns}->{$column_name} ) {
                push @{ $add_columns->{$table} }, $column;
            }

            # XXX TODO: compare the column definitions and alter them if necessary

        }
    }

    return ($add_tables, $add_columns, $remove_tables, $remove_columns );
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



sub connect_to_db_for_management {
    my $handle = Jifty::Handle->new();

    my $driver   = Jifty->config->framework('Database')->{'Driver'};

    # Everything but the template1 database is assumed
    my %connect_args;
    $connect_args{'database'} = 'template1' if ( $handle->isa("Jifty::DBI::Handle::Pg") );
    $connect_args{'database'} = ''          if ( $handle->isa("Jifty::DBI::Handle::mysql") );
    $handle->connect(%connect_args);
    return $handle;
}


1;