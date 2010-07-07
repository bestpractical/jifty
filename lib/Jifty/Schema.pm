use warnings;
use strict;

package Jifty::Schema;
use base qw/Jifty::Object/;
use SQL::ReservedWords;

=head1 NAME

Jifty::Schema - Jifty schemas

=cut

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

=head2 new

Returns a new Jifty::Schema. Takes no arguments. Will automatically figure out and initialize the models defined in the app's source.

=cut

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
