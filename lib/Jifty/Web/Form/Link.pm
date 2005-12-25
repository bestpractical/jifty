use warnings;
use strict;
 
package Jifty::Web::Form::Link;

=head1 NAME

Jifty::Web::Form::Link - Web input of some sort

=head1 DESCRIPTION

Describes an HTML link

=cut

use base qw/Jifty::Web::Form::Element Class::Accessor/;

sub accessors { shift->SUPER::accessors(), qw(url label); }
__PACKAGE__->mk_accessors(qw(url label));

=head2 new

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my %args = (
                url   => $ENV{PATH_INFO},
                label => undef,
                @_
               );

    for my $field ( $self->accessors() ) {
        $self->$field( $args{$field} ) if exists $args{$field};
    }

    return $self;
}

=head2 render

=cut

sub render {
    my $self = shift;
    
    my %base = ( (map {($_->key, $_->value)} Jifty->framework->request->state_variables) );
    for my $trigger ($self->handlers) {
        my $value = $self->$trigger;
        next unless $value;
        my @hooks = ref $value eq "ARRAY" ? @{$value} : ($value);
        for my $hook (@hooks) {
            $base{"region-@{[$hook->{region} || Jifty->framework->qualified_region]}.$_"} = $hook->{args}{$_}
              for grep {$hook->{args}{$_}} keys %{$hook->{args} || {}};
            $base{"region-@{[$hook->{region} || Jifty->framework->qualified_region]}"} = $hook->{fragment} if $hook->{fragment};
        }
    }
    
    my $result = "";
    $result .= qq!<a href="! . $self->url;
    $result .= qq!?! if %base;
    $result .= join(";", map {Jifty->mason->interp->apply_escapes("J:V-$_","u")."=".Jifty->mason->interp->apply_escapes($base{$_},"u")} keys %base);
    $result .= qq!"!;
    $result .= $self->javascript();
    $result .= ">". $self->label ."</a>";

    return $result;
}

1;
