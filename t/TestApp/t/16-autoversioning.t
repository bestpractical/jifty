#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Right now, this test script only tests that our schema diffing tool picks up the right things.
Next we'll want to try to apply the changes

=cut

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 28;

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
{
 $serialized = $schema->serialize_current_schema;
delete $serialized->{'TestApp::Model::User'}->{columns}->{tasty};
    my ( $add_tables, $add_columns, $remove_tables, $remove_columns )
            = $schema->compute_schema_diffs( $stored, $serialized);

is_deeply($add_tables, {});
is_deeply($add_columns, {});
is_deeply($remove_tables, {});
is_deeply([keys %$remove_columns], ['TestApp::Model::User' ]);
is_deeply($remove_columns->{'TestApp::Model::User'}[0]->{'name'}, 'tasty');
}


# remove a table, make sure it is picked up
{

 $serialized = $schema->serialize_current_schema;
delete $serialized->{'TestApp::Model::User'};
    my ( $add_tables, $add_columns, $remove_tables, $remove_columns )
            = $schema->compute_schema_diffs( $stored, $serialized);

is_deeply($add_tables, {});
is_deeply([keys %$remove_tables], ['TestApp::Model::User']);
is_deeply($remove_columns, {});
is_deeply($add_columns,{});
}


# add a column, make sure it is picked up
{
 $serialized = $schema->serialize_current_schema;

$serialized->{'TestApp::Model::User'}->{columns}->{speedy} = $serialized->{'TestApp::Model::User'}->{columns}->{tasty};
$serialized->{'TestApp::Model::User'}->{columns}->{speedy}->{name} = 'speedy';
    my ( $add_tables, $add_columns, $remove_tables, $remove_columns )
            = $schema->compute_schema_diffs( $stored, $serialized);

is_deeply($add_tables, {});
is_deeply($remove_tables, {});
is_deeply($remove_columns, {});
is_deeply([keys %$add_columns], ['TestApp::Model::User' ]);
is_deeply($add_columns->{'TestApp::Model::User'}[0]->{'name'}, 'speedy');
}




# add a table, make sure it is picked up

{
 $serialized = $schema->serialize_current_schema;
$serialized->{'TestApp::Model::Foobar'} = $serialized->{'TestApp::Model::User'};
$serialized->{'TestApp::Model::Foobar'}->{'class'} = "TestApp::Model::Foobar";
$serialized->{'TestApp::Model::Foobar'}->{'table'} = "foobar";

    my ( $add_tables, $add_columns, $remove_tables, $remove_columns )
            = $schema->compute_schema_diffs( $stored, $serialized);

is_deeply($remove_tables, {});
is_deeply([keys %$add_tables], ['TestApp::Model::Foobar']);
is_deeply($remove_columns, {});
is_deeply($add_columns,{});
}

1;

