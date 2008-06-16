package Jifty::Plugin::OpenID::Mixin::Model::User;
use strict;
use warnings;
use Jifty::DBI::Schema;
use base 'Jifty::DBI::Record::Plugin';
use URI;

=head1 NAME

Jifty::Plugin::OpenID::Mixin::Model::User - Mixin model user

=head1 DESCRIPTION

L<Jifty::Plugin::OpenID> mixin for the User model.  Provides an 'openid' column.

=cut

use Jifty::Plugin::OpenID::Record schema {

our @EXPORT = qw(has_alternative_auth link_to_openid);

column openid =>
  type is 'text',
  label is 'OpenID',
  hints is q{You can use your OpenID to log in quickly and easily.},
  is distinct,
  is immutable;

};

=head2 has_alternative_auth

=cut

sub has_alternative_auth { 1 }

=head2 register_triggers

=cut

sub register_triggers {
    my $self = shift;
    $self->add_trigger(name => 'validate_openid', callback => \&validate_openid, abortable => 1);
    $self->add_trigger(name => 'canonicalize_openid', callback => \&canonicalize_openid);
}

=head2 validate_openid

=cut

sub validate_openid {
    my $self   = shift;
    my $openid = shift;

    my $uri = URI->new( $openid );

    return ( 0, q{That doesn't look like an OpenID URL.} )
        if not defined $uri;

    my $temp_user = Jifty->app_class("Model", "User")->new;
    $temp_user->load_by_cols( openid => $uri->canonical );

    # It's ok if *we* have the openid we're looking for
    return ( 0, q{It looks like somebody else has claimed that OpenID.} )
        if $temp_user->id and ( not $self->id or $temp_user->id != $self->id );

    return 1;
}

=head2 canonicalize_openid

=cut

sub canonicalize_openid {
    my $self   = shift;
    my $openid = shift;

    return ''
        if not defined $openid or not length $openid;

    $openid = 'http://' . $openid
        if $openid !~ m{^https?://};

    my $uri = URI->new( $openid );

    return $uri->canonical;
}

=head2 link_to_openid

Links User's account to the specified OpenID (bypassing ACLs)

=cut

sub link_to_openid {
    my $self   = shift;
    my $openid = shift;
    $self->__set( column => 'openid', value => $openid );
}

1;
