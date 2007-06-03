use warnings;
use strict;

=head1 NAME

Jifty::RightsFrom

=head1 SYNOPSIS

  package Application::Model::Thing;
  use Jifty::DBI::Schema;
  use Application::Record schema {
    column owner => refers_to Application::Model::Person;
  }

  use Jifty::RightsFrom column => 'owner';

=head1 DESCRIPTION

Provides a C<delegate_current_user_can> method that various
task-related objects can use as a base to make their own access
control decisions based on their
task. L<Jifty::Record/current_user_can> uses this method to make an
access control decision if it exists.

Note that this means that a model class can use Jifty::RightsFrom,
and still have a custom C<current_user_can> method, and they will not
interfere with each other.

=cut

package Jifty::RightsFrom;
use base qw/Exporter/;


sub import {
    my $class = shift;
    export_curried_sub(
        sub_name  => 'delegate_current_user_can',
        as        => 'delegate_current_user_can',
        export_to => $class,
        args      => \@_
    );
}


=head2 export_curried_sub HASHREF

Takes:

=over

=item sub_name

The subroutine in this package that you want to export.

=item export_to

The name of the package you want to export to.

=item as

The name your new curried sub should be exported into in the package
C<export_to>


=item args (arrayref)

The arguments you want to hand to your sub.


=back

=cut

sub export_curried_sub {
    my %args = (
        sub_name     => undef,
        export_to => undef,
        as           => undef,
        args        =>  undef,
        @_
    );
    no strict 'refs';
    no warnings 'redefine';
    local *{ $args{'as'} } = sub { &{ $args{'sub_name'} }(shift @_, @{ $args{'args'} }, @_ ) };

    local @{Jifty::RightsFrom::EXPORT_OK} = ($args{as});
    Jifty::RightsFrom->export_to_level( 2, $args{export_to}, $args{as} );
}

=head2 delegate_current_user_can C<'column'>, C<$column_name>, C<$right_name>, C<@attributes>

Make a decision about permissions based on checking permissions on the
column of this record specified in the call to C<import>. C<create>,
C<delete>, and C<update> rights all check for the C<update> right on
the delegated object. On create, we look in the passed attributes for
an argument with the name of that column.

=cut

sub delegate_current_user_can {
    my $self        = shift;
    my $object_type = shift;    #always 'column' for now
    my $col_name    = shift;
    my $right       = shift;
    my %attribs     = @_;

    $right = 'update' if $right ne 'read';
    my $obj;

    my $column   = $self->column($col_name);
    my $obj_type = $column->refers_to();

    # XXX TODO: this card is bloody hard to follow. it's my fault. --jesse

    my $foreign_key = $attribs{ $column->name };
    # We only do the isa if the foreign_key is a reference
    # We could also do this using eval, but it's an order of magnitude slower
    if ( ref($foreign_key) and $foreign_key->isa($obj_type) ) {
        $obj = $foreign_key;    # the fk is actually an object
    } elsif (
        my $fk_value = (
                   $foreign_key
                || $self->__value( $column->name )
                || $self->{ $column->name }
        )
        )
    {
        $obj = $obj_type->new( current_user => $self->current_user );
        $obj->load_by_cols( ( $column->by || 'id' ) => $fk_value );
    } else {
        return 0;
    }

    return $obj->current_user_can($right);
}


1;

