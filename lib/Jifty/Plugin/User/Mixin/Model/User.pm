use strict;
use warnings;

package Jifty::Plugin::User::Mixin::Model::User;
use Jifty::DBI::Schema;


=head1 NAME

Jifty::Plugin::User::Mixin::Model::User - user model base mixin

=head1 SYNOPSIS

 package MyApp::Model::User;
 use Jifty::DBI::Schema;
 use MyApp::Record schema { 
     # column definitions
 };

 # Import columns: name, email and email_confirmed
 use Jifty::Plugin::User::Mixin::Model::User;

=head1 DESCRIPTION

This mixin may be added to a model to give your user accounts a name and an email address. This module may be used as the basic building block for building account models in your application. It can be combined with mixins from an authentication plugin to create an object suitable for a given authentication mechanism.

=head1 SCHEMA

This mixin model adds the following columns to the model.

=head2 name

This is the username/nickname for the user of the account.

=head2 email

This is the email address of the account. It is intended as a bare minimum confirmation of identity and for communication of password resets and other account information.

=head2 email_confirmed

This is a flag indicating whether the user has confirmed ownership of the given email address.
 
=cut

use base 'Jifty::DBI::Record::Plugin';
use Jifty::Plugin::User::Record schema {
    column
        name => type is 'text',
        label is _('Nickname'),
        hints is _('How should I display your name to other users?');
    column
        email => type is 'text',
        label is _('Email address'), default is '', is immutable, is distinct;
    column
        email_confirmed => label is _('Email address confirmed?'),
        render as 'Unrendered',
        type is 'boolean';

};

=head1 METHODS

=head2 set_email ADDRESS

Whenever a user's email is set to a new value, we need to make 
sure they reconfirm it.

=cut

{
    no warnings 'redefine';

sub set_email {
    my $self  = shift;
    my $new_address = shift;
    my $email = $self->__value('email');

    my @ret = $self->_set( column => 'email', value => $new_address);

    unless ( $email eq $self->__value('email') ) {
        $self->__set( column => 'email_confirmed', value => '0' );
        Jifty->app_class('Notification','ConfirmEmail')->new( to => $self )->send;
    }

    return (@ret);
}

}

=head2 validate_email

Makes sure that the email address looks like an email address and is
not taken.

=cut

sub validate_email {
    my $self      = shift;
    my $new_email = shift;
    
    return ( 0, _("That %1 doesn't look like an email address.", $new_email) )
        if $new_email !~ /\S\@\S/;
    
    my $temp_user = Jifty->app_class('Model','User')->new( current_user => Jifty->app_class('CurrentUser')->superuser );
    $temp_user->load_by_cols( 'email' => $new_email );
    
    # It's ok if *we* have the address we're looking for
    return ( 0, _('It looks like somebody else is using that address. Is there a chance you have another account?') )
        if $temp_user->id && ( !$self->id || $temp_user->id != $self->id );
    
    return 1;
}

=head1 SEE ALSO

L<Jifty::Plugin::Authentication::Password>, L<Jifty::Plugin::Authentication::Password::Mixin::Model::User>

=head1 LICENSE

Jifty is Copyright 2005-2010 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;

