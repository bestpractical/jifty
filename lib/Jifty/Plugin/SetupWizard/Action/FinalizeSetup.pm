package Jifty::Plugin::SetupWizard::Action::FinalizeSetup;
use strict;
use warnings;
use base 'Jifty::Action';

sub change_config {
    my $self   = shift;
    my $config = shift;

    # Disable admin mode (a requirement for SetupWizard)
    $config->{framework}{AdminMode} = 0;

    # Deactivate SetupWizard
    my @plugins = @{ $config->{framework}{Plugins} || [] };

    for my $plugin (@plugins) {
        my ($name) = keys %$plugin;
        if ($name =~ /SetupWizard/) {
            $plugin->{activated} = 0;

            # There may be multiple instances of SetupWizard (!) in the list,
            # so we don't "last" out here
        }
    }

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

It turns off admin mode, and sets the "activated" option of SetupWizard to
false.

=cut

