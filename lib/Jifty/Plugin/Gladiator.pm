package Jifty::Plugin::Gladiator;
use strict;
use warnings;
use base qw/Jifty::Plugin Class::Data::Inheritable/;
__PACKAGE__->mk_accessors(qw/prev_data/);

use Devel::Gladiator;
use Jifty::Util;

our $VERSION = 0.01;

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
        before_request => sub { $self->before_request(@_) }
    );

    Jifty::Handler->add_trigger(
        after_request => sub { $self->after_request }
    );
}

=head2 before_request

Log as much of the request state as we can.

=cut

sub before_request
{
    my $self    = shift;
    my $handler = shift;
    my $cgi     = shift;


    Jifty->log->error("Unable to probe for gladiatorg: $@") if $@;
}

=head2 after_request

Append the current user to the request log. This isn't done in one fell swoop
because if the server explodes during a request, we would lose the request's
data for logging.

This, strictly speaking, isn't necessary. But we don't always want to lug the
sessions table around, so this gets us most of the way there.

C<logged_request> is checked to ensure that we don't append the current
user if the current request couldn't be logged for whatever reason (perhaps
a serialization error?).

=cut

sub after_request {
    my $self = shift;

        my $type_map = {};
    eval {
        my $array = Devel::Gladiator::walk_arena();
    use Devel::Cycle;
        for my $entry (@$array) {
            find_cycle($entry);
            $type_map->{ ref($entry) }++;
        }
    };

    my $prev = $self->prev_data || {};
    for (keys %$type_map) {
        $type_map->{$_} -= $prev->{$_};
        delete $type_map->{$_} if $type_map->{$_} == 0;
    }

    warn "This request";
    warn Jifty::YAML::Dump($type_map);

    $self->prev_data($type_map);

}


=head1 NAME

Jifty::Plugin::Gladiator - find leaks

=head1 DESCRIPTION

This plugin will attempt to output diffs between the current contents of memory after each request.


=head1 USAGE

Add the following to your site_config.yml

 framework:
   Plugins:
     - Gladiator: {}

=head2 OPTIONS

=over 4


=back

=head1 SEE ALSO


=head1 COPYRIGHT AND LICENSE

Copyright 2007 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;


