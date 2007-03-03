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
    $self->add_trigger(name => 'before_create', callback => \&before_create, abortable => 1);
}



sub before_create {
    my $self = shift;
    my $args = shift;
    return undef unless ($args->{'color'} eq 'yellow');
    return 1;
}



1;
