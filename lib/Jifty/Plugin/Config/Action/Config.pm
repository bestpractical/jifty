package Jifty::Plugin::Config::Action::Config;
use strict;
use warnings;

use base qw/Jifty::Action/;
use UNIVERSAL::require;
use Jifty::YAML;
use File::Spec;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param
      database_type => label is 'Database type',    # loc
      render as 'Select', available are defer {
        my %map = (
            mysql  => 'MySQL',                      
            Pg     => 'PostgreSQL',                 
            SQLite => 'SQLite',                     
            Oracle => 'Oracle',                     
        );

        for ( keys %map ) {
            my $m = 'DBD::' . $_;
            delete $map{$_} unless $m->require;
        }

        [ map { { display => $map{$_}, value => $_ } } keys %map ];
      },
      default is defer { 
          Jifty->config->framework('Database')->{'Driver'}
      };
    param
      database_host => label is 'Database host',    # loc
      hints is
      "The domain name of your database server (like 'db.example.com')",    
      default is defer {
          Jifty->config->framework('Database')->{'Host'}
      };

    param
      database_name => label is 'Database name',                            
      default is defer {
          Jifty->config->framework('Database')->{'Database'}
      };
    param
      database_user => label is 'Database username',                 
      default is defer { 
          Jifty->config->framework('Database')->{'User'}
      };

    param
      database_password => label is 'Database password',             
      render as 'Password';
};

=head2 take_action

=cut

my %database_map = (
    name => 'Database',
    type => 'Driver',
);

sub take_action {
    my $self = shift;

    my $stash = Jifty->config->stash;
    for my $arg ( $self->argument_names ) {
        if ( $self->has_argument($arg) ) {
            if ( $arg =~ /database_(\w+)/ ) {
                my $key = $database_map{$1} || ucfirst $1;
                my $database = $stash->{'framework'}{'Database'};
                if ( $database->{$key} ne $self->argument_value($arg) ) {
                    $database->{$key} = $self->argument_value($arg);
                }
            }
        }
    }

    # hack
    # do *not* dump all the Plugins stuff because Plugins is arrayref
    # dumping all will cause duplicate problems
    # instead, we keep the old Plugins
    my $site_config_file = $ENV{'JIFTY_SITE_CONFIG'}
      || Jifty::Util->app_root . '/etc/site_config.yml';
    if ( -e $site_config_file ) {
        my $site_config = Jifty::YAML::LoadFile($site_config_file);
        $stash->{framework}{Plugins} = $site_config->{framework}{Plugins};
    }
    Jifty::YAML::DumpFile( $site_config_file, $stash );
    Jifty->config->load;
    $self->report_success unless $self->result->failure;

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
