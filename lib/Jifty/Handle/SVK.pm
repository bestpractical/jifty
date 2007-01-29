use warnings;
use strict;

package Jifty::Handle::SVK;
use Jifty::Util;
use Jifty::Handle;
use base 'Jifty::Handle';

=head1 NAME

Jifty::Handle::SVK -- Revision-controlled database handles for Jifty

=head1 SYNOPSIS

In your F<etc/config.yml>:

  framework:
    Database:
      HandleClass: Jifty::Handle::SVK

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}

sub connect {
    my $self = shift;
    my $rv = $self->SUPER::connect(@_);
    return $rv;
}

sub insert {
    my $self  = shift;
    my $table = shift;
    my $rv = $self->SUPER::insert($table, @_);
    return $rv;
}

sub delete {
    my $self = shift;
    my $rv = $self->SUPER::delete(@_);
    return $rv;
}

sub update_record_value {
    my $self = shift;
    my $rv = $self->SUPER::update_record_value(@_);
    return $rv;
}

sub begin_transaction {
    my $self = shift;
    my $rv = $self->SUPER::begin_transaction(@_);
    return $rv;
}

sub commit {
    my $self = shift;
    my $rv = $self->SUPER::commit(@_);
    return $rv;
}

sub rollback {
    my $self = shift;
    my $rv = $self->SUPER::rollback(@_);
    return $rv;
}

1;
