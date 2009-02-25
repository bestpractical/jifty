use strict;
use warnings;

package Jifty::Plugin::ActorMetadata;
use base qw/Jifty::Plugin/;

=head1 NAME

Jifty::Plugin::ActorMetadata - add created_by created_on updated_by updated_on columns to a model class

=head1 DESCRIPTION

This plugin adds a model mixin which adds C<created_by>,
C<created_on>, C<updated_by> and C<updated_on> columns to a model
class.

=head1 SYNOPSIS

 use strict;
 use warnings;
 
 package YourApp::Model::Thingy;
 use Jifty::DBI::Schema;
 
 use YourApp::Record schema {
 
         ...
 
 };
 use Jifty::Plugin::ActorMetadata::Mixin::Model::ActorMetadata;
 #Provides created_by, created_on, updated_by and updated_on
 

=cut

1;
