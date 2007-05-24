#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

This is a template for your own tests. Copy it and modify it.

=cut

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 1;

ok(1, "Loaded the test script");

Jifty->new;
my $schema = Jifty::Schema->new();
isa_ok($schema, 'Jifty::Schema');
can_ok($schema, 'models');
can_ok($schema, 'serialize_current_schema');

my $serialized = $schema->serialize_current_schema;
ok($schema->_store_current_schema);;
my $stored = $schema->_load_stored_schema();
is_deeply($stored,$serialized);
{
    my ( $add_tables, $add_columns, $remove_tables, $remove_columns )
            = $schema->compute_schema_diffs( $stored, $serialized);

is_deeply($add_tables, {});
is_deeply($add_columns, {});
is_deeply($remove_tables, {});
is_deeply($remove_columns, {});
}


# remove a column, make sure it is picked up
delete $serialized->{'TestApp::Model::User'}->{columns}->{tasty};
{
    my ( $add_tables, $add_columns, $remove_tables, $remove_columns )
            = $schema->compute_schema_diffs( $stored, $serialized);

is_deeply($add_tables, {});
is_deeply($add_columns, {});
is_deeply($remove_tables, {});
is_deeply([keys %$remove_columns], ['TestApp::Model::User' ]);
is_deeply($remove_columns->{'TestApp::Model::User'}[0]->{'name'}, 'tasty');
}




# remove a table, make sure it is picked up
# add a column, make sure it is picked up
# add a table, make sure it is picked up


1;

