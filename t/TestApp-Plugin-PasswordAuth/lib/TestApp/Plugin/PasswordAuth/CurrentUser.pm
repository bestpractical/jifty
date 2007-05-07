package TestApp::Plugin::PasswordAuth::CurrentUser;

use strict;
use warnings;

use base qw(Jifty::CurrentUser);

__PACKAGE__->mk_accessors(qw(group));

sub _init {
   my $self = shift;
   my %args = (@_);

   if (delete $args{'_bootstrap'} ) {
       $self->is_bootstrap_user(1);
   } elsif (keys %args) {
       $self->user_object(TestApp::Plugin::PasswordAuth::Model::User->new(current_user => $self));
       $self->user_object->load_by_cols(%args);

       if ( $self->user_object->mygroup eq 'admin') {
           $self->is_superuser(1);
       };

       $self->group($self->user_object->mygroup);
   };
   $self->SUPER::_init(%args);
};


1;
