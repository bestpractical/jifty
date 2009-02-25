package Jifty::Plugin::Gladiator;
use strict;
use warnings;
use base qw/Jifty::Plugin Class::Data::Inheritable/;
__PACKAGE__->mk_accessors(qw/prev_data/);

use Devel::Gladiator;
use List::Util 'reduce';

our @requests;

our $VERSION = 0.01;


=head1 NAME

Jifty::Plugin::Gladiator - Walk the areas, looking for leaked objects

=head1 DESCRIPTION

This plugin will attempt to output diffs between the current contents
of memory after each request, in order to track leaks.

=head1 USAGE

Add the following to your site_config.yml

 framework:
   Plugins:
     - Gladiator: {}

=head1 METHODS

=head2 init

init installs the trigger needed before each HTTP request. It also establishes
the baseline for all times and creates the log path.

=cut

sub init {
    my $self = shift;
    my %args = (
        @_,
    );

    return if $self->_pre_init;

    Jifty::Handler->add_trigger(
        after_request => sub { $self->after_request(@_) }
    );
}

=head2 after_request

=cut

sub after_request {
    my $self    = shift;
    my $handler = shift;
    my $cgi     = shift;

    # walk the arena, noting the type of each value
    my %types;
    for (@{ Devel::Gladiator::walk_arena() }) {
        ++$types{ ref $_ };
    }

    # basic stats
    my $all_values = reduce { $a + $b } values %types;
    my $all_types  = keys %types;
    my $new_values = 0;
    my $new_types  = 0;

    my %prev = %{ $self->prev_data || {} };

    # copy so when we modify %types it doesn't affect prev_data
    my %new_prev = %types;
    $self->prev_data(\%new_prev);

    # find the difference
    for my $type (keys %types) {
        my $diff = $types{$type} - ($prev{$type} || 0);

        if ($diff != 0) {
            $new_values += $diff;
            ++$new_types;
        }

        $types{$type} = {
            all => $types{$type},
            new => $diff,
        }
    }

    push @requests, {
        id         => 1 + @requests,
        url        => $cgi->url(-absolute=>1,-path_info=>1),
        time       => scalar gmtime,

        all_values => $all_values,
        all_types  => $all_types,
        new_values => $new_values,
        new_types  => $new_types,
        diff       => \%types,
    };
}

=head1 SEE ALSO

L<Jifty::Plugin::LeakTracker>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;


