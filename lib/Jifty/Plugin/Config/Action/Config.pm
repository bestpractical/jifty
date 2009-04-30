package Jifty::Plugin::Config::Action::Config;
use strict;
use warnings;

use base qw/Jifty::Action/;
use UNIVERSAL::require;
use Jifty::YAML;
use File::Spec;

use Scalar::Defer; 
sub arguments {
    my $self = shift;
    return $self->{__cached_arguments} if ( $self->{__cached_arguments} );
    my $args = {
        'etc/config.yml' => {
            render_as     => 'Textarea',
            rows => 60,
            default_value => defer {
                local $/;
                open my $fh, '<', Jifty::Util->app_root . '/etc/config.yml';
                return <$fh>;
            }
        },
    };

    return $self->{__cached_arguments} = $args;
}

=head2 take_action

=cut

sub take_action {
    my $self = shift;

    if ( $self->has_argument('etc/config.yml') ) {
        my $new_config = $self->argument_value( 'config' );
        eval { Jifty::YAML::Load( $new_config ) };
        if ( $@ ) {
# invalid yaml
            $self->result->message( _( "invalid yaml" ) );
            $self->result->failure(1);
            return;
        }
        else {
            if ( open my $fh, '>', Jifty::Util->app_root . '/etc/config.yml' ) {
                print $fh $new_config;
                close $fh;
            }
            else {
                $self->result->message(
                    _("can't write to etc/config.yml: $1") );
                $self->result->failure(1);
                return;
            }
        }
    }
    $self->report_success;

    Jifty->config->load;
    Jifty->web->tangent( url => '/__jifty/config/restart.html' );

    return 1;
}

=head2 report_success

=cut

sub report_success {
    my $self = shift;

    # Your success message here
    $self->result->message('Success');
}

1;
