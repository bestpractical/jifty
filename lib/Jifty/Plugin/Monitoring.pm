use strict;
use warnings;

package Jifty::Plugin::Monitoring;

use base qw/Jifty::Plugin Exporter/;
use Time::HiRes qw(gettimeofday tv_interval);

our $VERSION = 0.01;

=head1 NAME

Jifty::Plugin::Monitoring - Provides a framework for profiling and
monitoring services

=head1 SYNOPSIS

In your F<config.yml>:

  Plugins:
    - Monitoring: {}

By writing modules, and scheduling the running of C<jifty cron>,
repeating events can be scheduled at various frequencies.  It also
provides functionality for sampling and recording profiling or usage
statistics from your jifty application.

=head1 DESCRIPTION

The configuration in F<config.yml> accepts one possible parameter,
C<path>, which should be the base class under which all monitoring
classes are found.  This defaults to C<AppName::Monitor>.  C<path> may
also be an array refence of classes to search under.

Each class monitoring class should C<use Jifty::Plugin::Monitoring>.
This will import several functions, which allow you to write
monitoring code as follows:

  use Jifty::Plugin::Monitoring;
  monitor users => every 30 => minutes, sub {
      my $monitor = shift;
      my $collection = AppName::Model::UserCollection->new;
      $collection->unlimit;
      data_point all => $collection->count;

      data_point yaks => int(rand(100));
  };

Monitors must have distinct names.  Time units supported by this
syntax include the singular and plural forms of C<minute>, C<hour>,
C<day>, C<week>, C<month>, and C<year>.

=cut

__PACKAGE__->mk_accessors(qw/base_classes monitors now current_monitor/);

our @EXPORT = qw/monitor every
                 minute minutes
                 hour hours
                 day days
                 week weeks
                 month months
                 year years

                 data_point timer/;

BEGIN {
    for my $time (qw/minute hour day week month year/) {
        for my $plural ( "", "s" ) {
            my $method = $time . $plural;
            no strict 'refs';
            *{ __PACKAGE__ . "::" . $method }
                = sub { return $time };
        }
    }
}

=head2 EXPORTED FUNCTIONS

These methods are used in your monitoring classes to define monitors.

=head2 every

Syntactic sugar helper method, which allows you to write:

  every 3 => minutes, sub { ... };

or

  every qw/3 minutes/, sub { ... };

=cut

sub every {
    unshift @_, 1 if @_ == 2;
    my ($count, $units, $sub) = @_;
    $units =~ s/s$//;
    return ($count, $units, $sub);
}

=head2 monitor

Syntactic sugar which defines a monitor.  Use it in conjunction with
L</every>:

  monitor "name", every qw/3 minutes/ => sub { ... };

=cut

sub monitor {
    my ($self) = Jifty->find_plugin('Jifty::Plugin::Monitoring');
    $self ||= $Jifty::Plugin::Monitoring::self;
    $self->add_monitor(@_);
}

=head2 data_point NAME, VALUE [, CATEGORY]

Records a data point, associating C<NAME> to C<VALUE> at the current
time.  C<CATEGORY> defaults to the name of the monitor that the data
point is inside of.

=cut

sub data_point {
    my ($self) = Jifty->find_plugin('Jifty::Plugin::Monitoring');
    $self ||= $Jifty::Plugin::Monitoring::self;

    my $category = @_ == 3 ? shift : $self->current_monitor->{name};
    my ($name, $value) = @_;    
    
    my $data = Jifty::Plugin::Monitoring::Model::MonitoredDataPoint->new();
    $data->create(
        category => $category,
        sample_name => $name,
        value => $value,
        sampled_at => $self->now,
    );
}

=head2 timer MECH, URL

Uses L<Time::HiRes> to time how long it takes the given
L<WWW::Mechanize> object C<MECH> to retrueve the given C<URL>.
Returns the number of seconds elapsed.

=cut

sub timer {
    my $mech = shift;
    my $url = shift;
    
    my $t0 = [gettimeofday];
    $mech->get($url);
    return tv_interval($t0);
}

=head2 Other Syntactic Sugar Methods

The following methods simply return themselves:

=over

=item minute, minutes

=item hour, hours

=item day, days

=item week, weeks

=item month, months

=item year, years

=back

=head1 OBJECT METHODS

These are primarily used by
L<Jifty::Plugin::Monitoring::Command::Cron>; you will not need to call
these in most uses of this plugin.

=head2 init

Looks for and loads all monitoring classes.  During the loading
process, the monitors defined in each class are found and stored for
later reference.

=cut

sub init {
    my $self = shift;
    my %args = @_;
    my @path = $args{path} ? @{$args{path}} : (Jifty->app_class("Monitor"));
    $self->base_classes(\@path);
    $self->monitors({});
    local $Jifty::Plugin::Monitoring::self = $self;
    Jifty::Module::Pluggable->import(
        require => 1,
        search_path => \@path,
        except => qr/\.#/,
        sub_name => 'monitor_classes',
    );
    $self->monitor_classes;
}


=head2 add_monitor NAME COUNT UNIT SUB

A class method used to add a monitor with the given C<NAME> and
C<SUB>, which is scheduled to be run every C<COUNT> C<UNIT>s.

=cut

sub add_monitor {
    my $self = shift;
    my ($name, $count, $units, $sub) = @_;
    $self->monitors->{$name} = { name => $name, sub => $sub, count => $count, unit => $units };
}

=head2 last_run NAME

Looks up and returns the L<Jifty::Plugin::Monitoring::Model::LastRun>
object for this monitor; creates one if one does not exist, and sets
it to the previous round time it would have run.

=cut

sub last_run {
    my $self = shift;
    my ($name) = @_;
    my $last = Jifty::Plugin::Monitoring::Model::LastRun->new();
    $last->load_or_create( name => $name );
    return $last if $last->last_run;

    my $unit = $self->monitors->{$name}->{unit};
    my $now = Jifty::DateTime->now->truncate( to => $unit );
    warn "No last run time for monitor $name; inserting $now\n";
    $last->set_last_run($now);
    return $last;
}

=head2 current_user

Monitors presumable run as superuser; thus, this method returns the
application's superuser object.

=cut

sub current_user {
    return Jifty->app_class("CurrentUser")->superuser;
}

=head2 current_monitor

Returns a hashref, with keys of C<name>, C<sub>, C<count>, and
C<units>, which describe the monitor which is crrently running, if
any.

=head2 now

For consistency, the current concept of "now" is fixed while the
monitor is running.  Use this method to determine when "now" is.

=cut

=head2 run_monitors

For each monitor that we know of, checks to see if it is due to be
run, and runs it if it is.

=cut

sub run_monitors {
    my $self = shift;
    my $now = Jifty::DateTime->now->truncate( to => "minute" );
    $now->set_time_zone("UTC");
    $self->now($now);
    for my $name (keys %{$self->monitors}) {
        my $last = $self->last_run($name);
        my %monitor = %{$self->monitors->{$name}};
        my $next = $last->last_run->add( $monitor{unit}."s" => $monitor{count} );
        warn "For monitor $name, next $next, now $now\n";
        next unless $now >= $next;
        warn "Cron not being run often enough: we skipped a '$name'!\n"
          if $now >= $next->add( $monitor{unit}."s" => $monitor{count} );
        warn "Running monitor $name\n";
        $self->current_monitor(\%monitor);
        eval {
            $monitor{sub}->($self);
        };
        if (my $error = $@) {
            warn "Error running monitor $name: $error\n";
        } else {
            $last->set_last_run($now);
        }
    }
    $self->current_monitor(undef);
}

1;
