package Jifty::Plugin::Config::Action::AddConfig;
use strict;
use warnings;
use base 'Jifty::Action';

use Hash::Merge 'merge';

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
        type is 'text',
        hints are 'Example: /framework/Web/MasonConfig';

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

sub write_new_config {
    my $self       = shift;
    my $new_config = shift;

    my $file = Jifty::Util->app_root
             . '/'
             . $self->argument_value('target_file');

    my $existing_config = -r $file ? Jifty::YAML::LoadFile($file) : {};

    Hash::Merge::set_behavior('RIGHT_PRECEDENT');
    my $combined_config = merge($existing_config, $new_config);

    Jifty::YAML::DumpFile($file, $combined_config);
}

sub take_action {
    my $self = shift;

    my $context = $self->argument_value('context');
    my $field   = $self->argument_value('field');
    my $value   = $self->argument_value('value');

    my ($new_config, $pointer) = $self->contextualize($context);

    $self->log->info("Changing config $field (in context $context) to $value");
    $pointer->{$field} = $value;

    $self->write_new_config($new_config);

    Jifty->config->load;
}

1;

__END__

=head1 NAME

Jifty::Plugin::Config::Action::AddConfig - add a configuration entry

=head1 METHODS

=head2 contextualize

Takes a context string (slash-separated list of keys) and returns a pair of
hash-references: the "top" of the config (for merging) and the "current
pointer" into the "top" hashref for where the new config entry should go.

=head2 write_new_config

Merges the existing config file at C<target_file> with the new entry and
updates C<target_file>.

=head2 take_action

Sets C<field = value> at C<context> in C<target_file>.

=cut

