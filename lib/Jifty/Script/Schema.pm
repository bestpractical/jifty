use warnings;
use strict;

package Jifty::Script::Schema;
use base qw/Jifty::Script/;

use version;
use Jifty::DBI::SchemaGenerator;
use Jifty::Config;
use Jifty::Schema;

=head1 NAME

Jifty::Script::Schema - Create SQL to update or create your Jifty app's tables

=head1 SYNOPSIS

  jifty schema --setup      Creates or updates your application's database tables

 Options:
   --print            Print SQL, rather than executing commands

   --setup            Upgrade or install the database, creating it if need be
   --create-database  Only creates the database
   --drop-database    Drops the database
   --ignore-reserved-words   Ignore any SQL reserved words in schema definition
   --no-bootstrap     don't run bootstrap

   --help             brief help message
   --man              full documentation

=head1 DESCRIPTION

Manages your database.

=head2 options

=over 8

=item B<--print>

Rather than actually running the database create/update/drop commands,
Prints the commands to standard output

=item B<--create-database>

Send a CREATE DATABASE command.  Note that B<--setup>, below, will
automatically send a CREATE DATABASE if it needs one.  This option is
useful if you wish to create the database without creating any tables
in it.

=item B<--drop-database>

Send a DROP DATABASE command.  Use this in conjunction with B<--setup>
to wipe and re-install the database.

=item B<--setup>

Actually set up your app's tables.  This creates the database if need
be, and runs any commands needed to bring the tables up to date; these
may include CREATE TABLE or ALTER TABLE commands.  This option is
assumed if the database does not exist, or the database version is not
the same as the application's version.

=item B<--ignore-reserved-words>

Ignore any SQL reserved words used in table or column deffinitions, if
this option is not used and a reserved word is found it will cause an error.

=item B<--no-bootstrap>

don't run Bootstrap, mostly to get rid of creating initial data

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=cut

sub options {
    my $self = shift;
    return (
        $self->SUPER::options,
        $self->_schema_options
    );
}

sub _schema_options {
    return (
        "setup"                 => "setup_tables",
        "print|p"               => "print",
        "create-database|c"     => "create_database",
        "ignore-reserved-words" => "ignore_reserved",
        "drop-database"         => "drop_database",
        "no-bootstrap"          => "no_bootstrap",
    );
}

=head1 DESCRIPTION

Looks for all model classes of your Jifty application and generates
SQL statements to create or update database tables for all of the
models.  It either prints the SQL to standard output (B<--print>) or
actually issues the C<CREATE TABLE> or C<ALTER TABLE> statements on
Jifty's database.

(Note that even if you are just displaying the SQL, you need to have
correctly configured your Jifty database in
I<ProjectRoot>C</etc/config.yml>, because the SQL generated may depend
on the database type.)

By default checks for SQL reserved words in your table names and
column definitions, throwing an error if any are found.  

If you want to permanently turn this behaviour off you can set
CheckSchema to 0 in the database section of your applications config
file.

=head1 BUGS

Due to limitations of L<DBIx::DBSchema>, this probably only works with
PostgreSQL, MySQL and SQLite.

It is possible that some of this functionality should be rolled into
L<Jifty::DBI::SchemaGenerator>

=cut

=head1 METHODS

=head2 run

Prints a help message if the users want it. If not, goes about its
business.

Sets up the environment, checks current database state, creates or deletes
a database as necessary and then creates or updates your models' schema.

=cut

sub run {
    my $self = shift;

    $self->print_help();
    $self->setup_environment();
    $self->schema->setup_database();

    print "Done.\n";
}

=head2 setup_environment

Sets up a minimal Jifty environment.

=cut

sub setup_environment {
    my $self = shift;

    # Import Jifty
    Jifty::Util->require("Jifty");
    Jifty::Util->require("Jifty::Model::Metadata");
    Jifty->new( no_handle => 1, logger_component => 'SchemaTool', )
        unless Jifty->class_loader;

    # Set the flags for Jifty::Schema
    $self->schema->flags({    map { $_ => $self->{$_} }
                           values %{{$self->_schema_options}} });
}

=head2 schema

Returns the same Jifty::Schema object for each invocation of this script.

=cut

sub schema {
    my $self = shift;

    $self->{'SCHEMA'} ||= Jifty::Schema->new();
    return $self->{'SCHEMA'};
}

1;
