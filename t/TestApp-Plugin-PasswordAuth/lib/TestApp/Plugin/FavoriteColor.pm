use strict;
use warnings;

package TestApp::Plugin::FavoriteColor;
use base 'Jifty::DBI::Record::Plugin';
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
        column color => type is 'text', default is 'Blue';
    };



sub register_triggers {
    my $self = shift;
    $self->add_trigger(name => 'validate_color', callback => \&validate_color, abortable => 1);
    $self->add_trigger(name => 'canonicalize_color', callback => \&canonicalize_color, abortable => 0);
}


sub canonicalize_color {
    my $self = shift;
    my $color = shift;

    if ($color eq 'grey') {
        return 'gray';
    }
    return $color;

}

sub validate_color {
    my $self = shift;
    my $arg = shift;
    return undef unless ($arg eq 'gray');
    return 1;
}



1;
