use warnings;
use strict;

package Jifty::Script::Database;
use base qw/Jifty::Script/;


use File::Path ();


=head1 NAME

Jifty::Script::Database - script for loading/dumping data from Jifty

=head1 DESCRIPTION

This script performs database dumps/loads on the database. This is particularly useful if part of your schema is stored in the database.

=head1 API

=head2 actions

This script may perform one of the following actions.

=over

=item --load

This action loads a previously dumped database. It consumes the dumped file from standard input:

  bin/jifty database --load < jifty-dump.yml

Loads must be performed on YAML formatted data.

=item --dump

Dumping the database write out all of the data in your database to standard output:

  bin/jifty database --dump > jifty-dump.yml 

=back

=head2 options

These options may be used to modify how the actions operate.

=over

=item --replace

This option only makes sense when C<--load> is used. It tells the script to replace any records your existing database that are also found in the serialized file.

This replace is performed by each record's ID field.

=item --format (YAML|Perl)

This option only makes sense when C<--dump> is used. It tells the script which serialized format to dump the records into. If this option is not specified the YAML format is used. The available options are:

=over

=item YAML

The file is dumped in YAML format in three levels:

  Model:
    UUID:
      column: value

At the top level, each model is named followed by a list of records to import keyed by their UUID. Under each UUID is the list of columns and values for those columns.

=item Perl

This format is mostly intended for debugging. The data is dumped into a Perl script that could be run to create the records in the database. This may be useful for testing or debugging your database. However, this format cannot be used by C<--load>, which provides a more robust mechanism for performing data import.

=back

=back

=cut

sub options {
    (
     'dump'       => 'dump',
     'load'       => 'load',
     'replace'    => 'replace',
     'format=s'   => 'format',
    )
}

=head2 run

Dump or load the current database.


=cut

sub run {
    my $self = shift;
    Jifty->new();

    if ($self->{dump}) { $self->dump(); }
    elsif ($self->{load}) { $self->load(); }
    else {
        print STDERR "You need to specify either --load or --dump\n";
    }
}


=head2 load

Reads a database dumpfile in YAML format on STDIN. Creates or updates your internal database as necessary.


=cut

sub load {
    my $self = shift;
    my @content = <STDIN>;
    my $content = Jifty::YAML::Load(join('',@content));
    #print Jifty::YAML::Dump($content)."\n";

    $self->_load_data($content);
}


sub _load_data {
    my $self = shift;
    my $content = shift;
    Jifty->handle->begin_transaction();
    # First the core stuff
    
    $self->upgrade_schema($content->{'Jifty::Model::ModelClass'}, $content->{'Jifty::Model::ModelClassColumn'});
    
    foreach my $class (grep { /^Jifty::Model/ } keys %$content) { 
        next if ($class =~ /^Jifty::Model::ModelClass(?:Column)?/); 
        $self->load_content_for_class($class => $content->{$class});
    }
    # Then the user stuff
    foreach my $class (grep {! /^Jifty::Model/ } keys %$content) { 
        $self->load_content_for_class($class => $content->{$class});
    }
    Jifty->handle->commit;
}


=head2 load_content_for_class CLASSNAME HASH

Loads a hash of data into records of type CLASSNAME

=cut


sub load_content_for_class {
    my $self    = shift;
    my $class   = shift;
    my $content = shift;
    local $@;
    eval {Jifty::Util->require($class)};

        if ($@)  { $self->log->fatal(
        "There's no locally defined class called $class. Without that, we can't insert records into it: $@"
        );
    }
    my $current_user = Jifty->app_class('CurrentUser')->new( _bootstrap => 1 );
    foreach my $id ( sort keys %$content ) {
        my $obj = $class->new( current_user => $current_user );
        if ( $self->{'replace'} ) {
            $obj->load_by_cols( id => $content->{$id}->{id} );
            if ( $obj->id ) {
                $obj->delete();
            }
        }

        my ( $val, $msg ) = $class->create( %{ $content->{$id} }, __uuid => $id );
        if ($val) {
            $self->log->info("Inserting $id into $class: $val");
        } else {
            $self->log->fatal(
                "Failed to insert $id into $class: $val");

        }

    }

}

=head2 upgrade_schema tablehash columnhash

Modify the current database's schema (virtual models and columns) to match that of the table hash and column hash.


=cut


sub upgrade_schema {
    my $self           = shift;
    my $new_tables     = shift;
    my $columns        = shift;

    my $current_tables = Jifty::Model::ModelClassCollection->new();
    $current_tables->unlimit();
    while ( my $table = $current_tables->next ) {
        $self->log->debug("Thinking about upgrading table ".$table->name . "(".$table->__uuid .")");
        if ( my $new_table = delete $new_tables->{ $table->__uuid } ) {
            $self->log->debug("It has the same uuid as the proposed replacement");

            # we have the same table in the db and the dump
            # let's sync its attributes from the dump then sync its columns
            foreach my $key ( keys %$new_table ) {
                $self->log->debug("Considering updating table attribute $key");
                unless ( $table->$key() eq $new_table->{$key} ) {
                    my $method = "set_" . $key;
                    $table->$method( $new_table->{$key} );
                }
            }

            my $current_columns = $table->included_columns;
            my $new_columns     = {};
            map {
                delete $_->{id};   # the id is only important on the first system
                $new_columns->{ $_->__uuid } = $_
                } grep { $_->{model_class} = $table->{__uuid} } values %$columns;

            while ( my $column = $current_columns->next ) {

                # First, update ones we know about
                if ( my $new_column = delete $new_columns->{ $column->__uuid } )
                {
                    foreach my $key ( keys %$new_column ) {
                        unless ( $column->$key() eq $new_column->{$key} ) {
                            my $method = "set_" . $key;
                            $column->$method( $new_column->{$key} );
                        }
                    }

                }

                # Second, delete columns that aren't in the dump file
                else {
                    $column->delete();
                }

                # Third, add columns that are only in the dumpfile
            }

            foreach my $col ( keys %$new_columns ) {
                Jifty::Model::ModelClassColumn->create($new_columns->{$col}, __uuid => $col);
            }

        } else {
            $self->log->debug("The new datamodel doesn't have this table anymore. Deleting");

            # we don't have the table anymore. That means we should delete it.
            # XXX TODO: this automatically deletes all the columns
            $table->delete();
        }

        # now we only have tables that were not yet in the database;
    }
    $self->_upgrade_create_new_tables( $new_tables => $columns );
}

sub _upgrade_create_new_tables {
    my $self       = shift;
    my $new_tables = shift;
    my $columns    = shift;
    use Data::Dumper;
    Test::More::diag('_upgrade_create_new_table: '.Dumper($self, $new_tables, $columns));
    foreach my $table_id ( keys %$new_tables ) {
        my $table = $new_tables->{$table_id};
        $self->log->debug("Creating a new table: ".$table->{name});
        delete $table->{id};
        my $class = Jifty::Model::ModelClass->new();
        my ( $val, $msg ) = $class->create( %{$table}, __uuid => $table_id );
        Test::More::diag('CREATE: '.Dumper($val, $msg, $class, $table, $table_id));
        die ($msg||'Unknown error during create.') unless ($val) ;
        # Now that we have a brand new model, let's find all its columns
        my @cols = grep { $_->{model_class} = $table->{__uuid} } values %$columns;
        foreach my $col (@cols) {
            delete $col->{id};
            $col->{model_class} = $class;
            Jifty::Model::ModelClassColumn->create(%$col);
        }
    }

}

=head2 dump

Dump the current database state as a YAML hash to STDOUT

=cut

sub dump {
    my $self = shift;
    my $content = $self->_models_to_hash();

    $self->{format} ||= 'yaml';

    if ($self->{format} =~ /^perl$/i) {
        $self->dump_as_perl($content);
    }
    elsif ($self->{format} =~ /^yaml$/i) {
        print Jifty::YAML::Dump($content)."\n";
    }
    else {
        print STDERR "Unknown --format option given.\n";
    }
}

sub _models_to_hash {
        my $self = shift;
        my $content = {};
        foreach my $model (Jifty->class_loader->models, qw(Jifty::Model::Metadata Jifty::Model::ModelClass Jifty::Model::ModelClassColumn)) {

        my $current_user = Jifty->app_class('CurrentUser')->new( _bootstrap => 1 );

        next unless $model->isa('Jifty::Record');
        my $collection = $model."Collection";
        Jifty::Util->require($collection);
        my $records = $collection->new( current_user => $current_user );
        $records->unlimit();

        foreach my $item ( @{ $records->items_array_ref } ) {
            my $ds = {};
            for ( $item->columns ) {
                next if $_->virtual;
                my $value;

                # If it's a reference and we can get its uuid, do that
                if ( UNIVERSAL::isa( $_->refers_to, 'Jifty::DBI::Record' ) ) {
                    my $obj = $item->_to_record( $_->name => $item->__value( $_->name ) );
                    $value = $obj->id ? $obj->__uuid : $item->__value( $_->name );

                } else {

                    $value = $item->__value( $_->name );
                }
                next unless defined $value;
                $ds->{ $_->name } = $value;
            }
            $content->{$model}->{  $item->__uuid } = $ds;
        }


    }
    return $content;
}

=head2 dump_as_perl

Outputs the data into a Jifty-ized Perl format. This is great for building operations to fill a test database from one you've already built up.

=cut

sub dump_as_perl {
    my ($self, $content) = @_;

    print 'my $record;',"\n";
    for my $model (keys %$content) {
        print "\$record = $model\->new;\n\n";

        my $records = $content->{$model};
        for my $uuid (keys %$records) {
            my $columns = $records->{$uuid};

            print "\$record->create(\n";
            print "    __uuid => '$uuid',\n";

            for my $column (%$columns) {
                if (defined $columns->{$column}) {
                    print "    $column => '$columns->{$column}',\n";
                }
            }

            print ");\n\n";
        }
    }
}

1;
