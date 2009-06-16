package Jifty::Plugin::SetupWizard::Action::FinalizeSetup;
use strict;
use warnings;
use base 'Jifty::Action';

sub change_config {
    my $self   = shift;
    my $config = shift;

    $config->{framework}{AdminMode} = 0;
    $config->{framework}{SetupMode} = 0;

    return $config;
}

sub take_action {
    my $self = shift;

    my $file = Jifty::Util->app_root . '/etc/site_config.yml';

    my $existing_config = -r $file
                        ? Jifty::YAML::LoadFile($file)
                        : {};

    my $new_config = $self->change_config($existing_config);

    Jifty::YAML::DumpFile($file, $new_config);
}

1;

__END__

=head1 NAME

Jifty::Plugin::SetupWizard::Action::FinalizeSetup

=head1 METHODS

=head2 take_action

Writes the config settings for finalizing and deactivating the setup wizard.

It turns off admin mode and setup mode.

=cut

