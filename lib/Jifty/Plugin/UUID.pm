use strict;
use warnings;

package Jifty::Plugin::UUID;
use base qw/Jifty::Plugin Class::Accessor::Fast/;

=head1 NAME

Jifty::Plugin::UUID - Provides Universally Unique Identifier for Jifty

=head1 SYNOPSIS

In your model class schema description, add the following:

    column photo => is UUID;


=head1 DESCRIPTION

This plugin provides user pictures for Jifty;


=cut

use Jifty::DBI::Schema;
use Data::UUID;
use Scalar::Defer;
my $UUID_GEN = Data::UUID->new();

my $UUID = defer { $UUID_GEN->create_str() } ;
sub _uuid {
    my ($column, $from) = @_;
    $column->readable(1);
    $column->writable(1);
    $column->default($UUID);
    $column->type('varchar(32)');
}

Jifty::DBI::Schema->register_types(
    UUID => sub {  _init_handler is \&_uuid,  render_as 'Jifty::Plugin::UUID::Widget'},
);




1;
