package Jifty::Plugin::Config::Action::AddConfig;
use strict;
use warnings;
use base 'Jifty::Action';

use Hash::Merge;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param field =>
        is mandatory,
        type is 'text';

    param value =>
        is mandatory,
        type is 'text';

    param context =>
        default is '/',
        type is 'text';

    param target_file =>
        default is 'etc/site_config.yml',
        type is 'text';
};

sub contextualize {
    my $self    = shift;
    my $context = shift;

    my $top = {};
    my @fragments = grep { length } split '/', $context;

    my $pointer = $top;
    for my $fragment (@fragments) {
        $pointer = $pointer->{$fragment} ||= {};
    }

    return ($top, $pointer);
}

sub take_action {
    my $self = shift;
    my ($new_config, $pointer) = $self->contextualize($self->argument_value('context'));
    $pointer->{$self->argument_value('field')} = $self->argument_value('value');

    # Hash::Merge site_config with $new_config
    # Restart server
}

1;

