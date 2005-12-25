use warnings;
use strict;

=head1 NAME

Jifty::::RightsFrom

=head1 DESCRIPTION

Provides a current_user_can method that various task-related objects 
can use as a base to make their own access control decisions based on 
their task.


=cut

package Jifty::RightsFrom;
use base qw/Exporter/;


sub import {
    my $class = shift;
    export_curried_sub(
        sub_name  => '_current_user_can',
        as        => 'current_user_can',
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
    # XXX TODO clkao points out that this call should use Hook::LexWrap
    local *{ $args{'as'} } = sub { \&{  $args{'sub_name'} }(shift @_, @{ $args{'args'} }, @_ ) };

    local @{Jifty::RightsFrom::EXPORT_OK} = ($args{as});
    Jifty::RightsFrom->export_to_level( 2, $args{export_to}, $args{as} );
}
1;
=head2 current_user_can

Seeing and editing task transactions (as well as other activities) are
based on your rights on the
task the transactions are on.  Some finagling is necessary because, if
this is a create call, this object does not have a C<task_id> yet, so
we must rely on the value in the I<ATTRIBUTES> passed in.

=cut

sub _current_user_can {
    my $self    = shift;
    my $object_type = shift; #always 'column' for now
    my $col_name = shift;
    my $right   = shift;
    my %attribs = @_;
    $right = 'update' if $right ne 'read';
    my $obj;

    my $column   = $self->column($col_name);
    my $obj_type = $column->refers_to();


    if ( UNIVERSAL::isa( $attribs{ $column->name }, $obj_type ) ) {
        $obj = $attribs{ $column->name };
    } elsif ( $attribs{ $column->name }
        || $self->__value( $column->name )
        || $self->{ $column->name } )
    {
        $obj = $obj_type->new( current_user => $self->current_user );
        $obj->load_by_cols(
                   ( $column->by || 'id' ) => $attribs{ $column->name }
                || $self->__value( $column->name )
                || $self->{ $column->name } );
    } else {
        return 0;
    }
    return $obj->current_user_can($right);
}

1;

