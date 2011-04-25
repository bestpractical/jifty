use strict;
use warnings;

package TestApp::Plugin::FasterSwallow;
use base 'Jifty::DBI::Record::Plugin';
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
        column swallow_type => valid are qw(african european), default is 'african';
    };


sub register_triggers {
    my $self = shift;
    $self->add_trigger(name => 'before_create', callback => \&before_create, abortable => 1);
}

sub before_create {
    my $self = shift;
    my $args = shift;
    return undef unless ($args->{'swallow_type'} eq 'african');
    return 1;
}

1;
