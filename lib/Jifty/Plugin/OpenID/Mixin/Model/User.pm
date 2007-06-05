package Jifty::Plugin::OpenID::Mixin::Model::User;
use strict;
use warnings;
use Jifty::DBI::Schema;
use base 'Jifty::DBI::Record::Plugin';
use URI;

use Jifty::Plugin::OpenID::Record schema {

our @EXPORT = qw(has_alternative_auth link_to_openid);

column openid =>
  type is 'text',
  label is 'OpenID',
  hints is q{You can use your OpenID to log in quickly and easily.},
  is distinct,
  is immutable;

};

sub has_alternative_auth { 1 }

sub register_triggers {
    my $self = shift;
    $self->add_trigger(name => 'validate_openid', callback => \&validate_openid, abortable => 1);
    $self->add_trigger(name => 'canonicalize_openid', callback => \&canonicalize_openid);
}

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

sub canonicalize_openid {
    my $self   = shift;
    my $openid = shift;

    return ''
        if not defined $openid or not length $openid;

    $openid = 'http://' . $openid
        if $openid !~ m{^http://};

    my $uri = URI->new( $openid );

    return $uri->canonical;
}

sub link_to_openid {
    my $self   = shift;
    my $openid = shift;
    $self->__set( column => 'openid', value => $openid );
}

1;
