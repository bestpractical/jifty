use strict;
use warnings;

package Jifty::Plugin::ActorMetadata;
use base qw/Jifty::Plugin/;

=head1 NAME

Jifty::Plugin::ActorMetadata

=head1 DESCRIPTION
 
This plugin adds a model mixin which adds C<created_by>, C<created_on> and C<updated_on> columns to a model class.

=head1 EXAMPLE 

use strict;
 use warnings;
 
 package MeetMeow::Model::Cat;
 use Jifty::DBI::Schema;
 
 use MeetMeow::Record schema {
 
         ...
 
 };
 use Jifty::Plugin::ActorMetadata::Mixin::Model::ActorMetadata; # created_by, created_on, updated_on
 

=cut

1;
