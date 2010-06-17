package Jifty::Plugin::SetupWizard;
use strict;
use warnings;
use base 'Jifty::Plugin';

__PACKAGE__->mk_accessors(qw(opts steps));

sub prereq_plugins { 'Config' }

sub init {
    my $self = shift;
    return if $self->_pre_init;

    my %opt = @_;

    if ($opt{steps}) {
        $self->steps($opt{steps});
    }
    elsif ( not $opt{'nodefault'} ) {
        $self->steps([
            {
                template    => 'welcome',
                header      => 'Welcome',
                hide_button => 1,
            },
            # Not sure this is worth doing quite yet.
#            {
#                template => 'language',
#                header   => 'Choose a Language',
#            },
            {
                template => 'database',
                header   => 'Database',
            },
            {
                template => 'web',
                header   => 'Web',
            },
            {
                template    => 'finalize',
                header      => 'Finalize',
                hide_button => 1,
            },
        ]);
    }
    else {
        $self->steps([]);
    }

    for my $step (@{ $opt{add_steps} || [] }) {
        $self->add_step(%$step);
    }
    
    # Save our config options for later
    $self->opts( \%opt );
}

sub add_step {
    my $self = shift;
    my %step = @_;

    # Keep finalize at the end
    if ($self->steps->[-1]->{template} eq 'finalize') {
        splice @{ $self->steps }, -1, 0, \%step;
    }
    else {
        push @{ $self->steps }, \%step;
    }
}

1;

__END__

=head1 NAME

Jifty::Plugin::SetupWizard - make it easy for end-users to set up your app

=head1 DESCRIPTION

    http://your.app/__jifty/admin/setupwizard

=head1 USAGE

Add the following to your site_config.yml to use the default generic setup
wizard:

    framework:
      Plugins:
        - SetupWizard: {}

You may write your own steps to add to the generic steps:

    framework:
      Plugins:
        - SetupWizard:
            add_steps:
              - template: /setup/bar
                header: MyApp's Bar
              - template: /setup/baz
                header: Baz

Or you may replace the generic steps altogether, but still use the generic
wizard flow:

    framework:
      Plugins:
        - SetupWizard:
            steps:
              - template: /setup/bar
                header: MyApp's Bar
              - template: /setup/baz
                header: Baz

Finally, you can disable the generic wizard and default setup steps entirely
and just use the helpers provided by this plugin.

    framework:
      Plugins:
        - SetupWizard:
            nodefault: 1

=head1 METHODS

=head2 init

Sets up a L</post_init> hook.

=head2 add_step(%params)

Adds another step to the setup wizard. It will go at the end, but before the
"finalize" step if it exists.

=head2 prereq_plugins

This plugin depends on L<Jifty::Plugin::Config>.

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

