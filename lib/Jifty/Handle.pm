use warnings;
use strict;

package Jifty::Handle;

=head1 NAME

Jifty::Handle -- A database handle class for Jifty

=head1 DESCRIPTION

A wrapper around Jifty::DBI::Handle to do our special stuff

=cut

use Jifty::Everything;
our @ISA;

=head1 METHODS

=head2 new PARAMHASH

This class method instantiates a new C<JiftyHandle> object. This object deals
with  database handles for the system.

=cut


# Setup database handle based on config data
sub new {
    my $class = shift;


    if (Jifty->config->framework('Database')->{Driver} eq 'Oracle') {
        $ENV{'NLS_LANG'} = "AMERICAN_AMERICA.AL32UTF8";
        $ENV{'NLS_NCHAR'} = "AL32UTF8";
    }
   
    # We do this to avoid Jifty::DBI::Handle's magic reblessing, because
    # it breaks subclass methods.
    my $driver_class  = "Jifty::DBI::Handle::".  Jifty->config->framework('Database')->{Driver};
    $driver_class->require;
    unshift @ISA, $driver_class;
    return $class->SUPER::new();
}

=head2 connect ARGS

A subclass method of Jifty::DBI::Handle that defaults to our default DB config

=cut

sub connect {
    my $self = shift;
    my %args = (@_);
    my %db_config =  %{Jifty->config->framework('Database')};
    
    my %lc_db_config;
    for (keys %db_config) {
        $lc_db_config{lc($_)} = $db_config{$_};
    }
    $self->SUPER::connect( %lc_db_config , %args);
    $self->dbh->{LongReadLen} = Jifty->config->framework('MaxAttachmentSize') || '10000000';
}


=head2 check_schema_version

Make sure that we have a recent enough database schema.  If we don't,
then error out.

=cut

sub check_schema_version {
    my $appv
        = version->new( Jifty->config->framework('Database')->{'Version'} );
    my $dbv = Jifty::Model::Schema->new->in_db;
    die
        "Schema has no version in the database; perhaps you need to run bin/jifty schema --install?\n"
        unless defined $dbv;

    die
        "Schema version in database ($dbv) doesn't match application schema version ($appv)\n"
        . "Please run `bin/jifty schema --install` to upgrade the database.\n"
        unless $appv == $dbv;

}


=head1 AUTHOR

Various folks at BestPractical Solutions, LLC.

=cut

1;
