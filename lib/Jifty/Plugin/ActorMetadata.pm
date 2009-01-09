use strict;
use warnings;

package Jifty::Plugin::ActorMetadata;
use base qw/Jifty::Plugin/;

=head1 NAME

Jifty::Plugin::ActorMetadata - add created_by created_on updated_by updated_on columns to a model class

=head1 DESCRIPTION

This plugin adds a model mixin which adds C<created_by>, C<created_on>, C<updated_by> and C<updated_on> columns to a model class.

=head1 EXAMPLE 

use strict;
 use warnings;
 
 package MeetMeow::Model::Cat;
 use Jifty::DBI::Schema;
 
 use MeetMeow::Record schema {
 
         ...
 
 };
 use Jifty::Plugin::ActorMetadata::Mixin::Model::ActorMetadata; # created_by, created_on, updated_by and updated_on
 

=cut

1;
