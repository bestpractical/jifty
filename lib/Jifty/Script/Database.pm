use warnings;
use strict;

package Jifty::Script::Database;
use base qw/App::CLI::Command/;


use File::Path ();


=head1 NAME

Jifty::Script::Database 

=head1 DESCRIPTION

When you're getting started with Jifty, this is the server you
want. It's lightweight and easy to work with.

=head1 API

=head2 options


=cut

sub options {
    (
     'dump'       => 'dump',
     'load'       => 'load',
     'replace'  => 'replace',
    )
}

=head2 run


=cut

sub run {
    my $self = shift;
    Jifty->new();

    if ($self->{dump}) { $self->dump(); }
    elsif ($self->{load}) { $self->load(); }
}

sub load {
    my $self = shift;
    my @content = <STDIN>;
    my $content = Jifty::YAML::Load(join('',@content));
    print Jifty::YAML::Dump($content)."\n";
    Jifty->handle->begin_transaction();
    # First the core stuff
    foreach my $class (grep { /^Jifty::Model/ } keys %$content) { 
        next if ($class =~ /^Jifty::Model::ModelClass(?:Column)?/); 
        $self->load_content($class => $content->{$class});
    }
    # Then the user stuff
    foreach my $class (grep {! /^Jifty::Model/ } keys %$content) { 
        $self->load_content($class => $content->{$class});
    }
}

sub load_content {
    my $self    = shift;
    my $class   = shift;
    my $content = shift;
    Jifty::Util->require($class)
        || Jifty->logger->log->fatal(
        "There's no locally defined class called $class. Without that, we can't insert records into it"
        );

    my $current_user = Jifty::CurrentUser->new( _bootstrap => 1 );
    foreach my $id ( sort keys %$content ) {
        my $obj = $class->new( current_user => $current_user );
        if ( $self->{'replace'} ) {
            $obj->load_by_cols( id => $content->{$id}->{id} );
            if ( $obj->id ) {
                $obj->delete();
            }
        }

        my ( $val, $msg ) = $class->create( %{ $content->{$id} } );
        if ($val) {
            Jifty->logger->log->info("Inserting $id into $class: $val");
        } else {
            Jifty->logger->log->fatal(
                "Failed to insert $id into $class: $val");

        }

    }

}


sub upgrade_schema {
    my $self           = shift;
    my $new_tables     = shift;
    my $columns        = shift;
    my $current_tables = Jifty::Model::ModelClassCollection->new();
    $current_tables->unlimit();
    while ( my $table = $current_tables->next ) {
        if ( my $new_table = $new_tables->{ $table->uuid } ) {

            # we have the same table in the db and the dump
            # let's sync its attributes from the dump then sync its columns
            foreach my $key ( keys %$new_table ) {
                unless ( $table->$key() eq $new_table->{$key} ) {
                    my $method = "set_" . $key;
                    $table->$method( $new_table->{$key} );
                }
            }

            my $existing_cols = {};
            map { $existing_cols->{ $_->uuid } = $_ }
                @{ $table->included_columns };

            # Now that we've taken care of that, let's sync up our columns.
            foreach my $col ( grep { $_->{model_class} = $table->{uuid} }
                values %$columns ) {
                delete
                    $col->{id}; # the id is only important on the first system

                # if we already have such a column, update it.
                if ( my $existing_col = $existing_cols->{ $col->{uuid} } ) {
                    foreach my $key ( keys %$col ) {
                        unless ( $existing_col->$key() eq $col->{$key} ) {
                            my $method = "set_" . $key;
                            $existing_col->$method( $col->{$key} );
                        }
                    }

                    delete $existing_cols->{ $col->{uuid} };

                }

                #otherwise we need to add it
                else {
                    Jifty::Model::ModelClassColumn->create(%$col);
                }
            }

            # now that we've added all the columns we care about and
            # modded the ones we know, everything left is something to delete;

            for ( values %$existing_cols ) {
                $_->delete;
            }

            delete $new_tables->{ $table->uuid };
        } else {

            # we don't have the table anymore. That means we should delete it.
            # XXX TODO: this automatically deletes all the columns
            $table->delete();
        }

        # now we only have tables that were not yet in the database;
        $self->_upgrade_create_new_tables( $new_tables => $columns );
    }
}


sub _upgrade_create_new_tables {
    my $self       = shift;
    my $new_tables = shift;
    my $columns    = shift;
    foreach my $table ( values %$new_tables ) {
        delete $table->{id};
        my $class = Jifty::Model::ModelClass->new();
        my ( $val, $msg ) = $class->create( %{$table} );

        # Now that we have a brand new model, let's find all its columns
        my @cols = grep { $_->{model_class} = $table->{uuid} } values %$columns;
        foreach my $col (@cols) {
            delete $col->{id};
            Jifty::Model::ModelClassColumn->create(%$col);
        }
    }

}



sub dump {
    my $self = shift;
    my $content = {};
 foreach my $model (Jifty->class_loader->models, qw(Jifty::Model::Metadata Jifty::Model::ModelClass Jifty::Model::ModelClassColumn)) {
        next unless $model->isa('Jifty::Record');
        my $collection = $model."Collection";
        Jifty::Util->require($collection);
        my $records = $collection->new;
        $records->unlimit();

        foreach my $item ( @{ $records->items_array_ref } ) {
            my $ds = {};
            for ( $item->columns ) {
                next if $_->virtual;
                my $value;

                # If it's a reference and we can get its uuid, do that
                if ( UNIVERSAL::isa( $_->refers_to, 'Jifty::DBI::Record' ) ) {
                    my $obj = $item->_to_record( $_->name => $item->__value( $_->name ) );
                    $value = $obj->__value('uuid') || $item->__value( $_->name );

                } else {

                    $value = $item->__value( $_->name );
                }
                next unless defined $value;
                $ds->{ $_->name } = $value;
            }
            $content->{$model}
                ->{ ( $item->can('uuid') ? $item->uuid : $item->id ) } = $ds;
        }


    }
    print Jifty::YAML::Dump($content)."\n";
    
}

1;
