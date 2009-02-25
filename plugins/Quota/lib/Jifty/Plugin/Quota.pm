use strict;
use warnings;

package Jifty::Plugin::Quota;

use base qw/Jifty::Plugin/;

=head1 NAME

Jifty::Plugin::Quota - Provides a framework for generic quota management
of Jifty model objects

=head1 SYNOPSIS

In your F<config.yml>:

  Plugins:
    - Quota:
        disk:
          User: 5242880   # bytes (5MB)
          Group: 10485760

By inserting hooks and checks into an app (actions and models, most
likely), quotas can be updated and enforced.  It is up to the developer to
do this though; this plugin just provides a ready-made framework.

The configuration provides defaults for quota creation.  It is structured
by I<type> and then I<object_class>.  In the example above, the default disk
space quotas for User and Group model objects are set.  When a new quota is
created and a I<cap> is not specified, the plugin will look up the default
in the config.

=head1 METHODS

=head2 config

=cut

__PACKAGE__->mk_accessors(qw(config));

=head2 init

=cut

sub init {
    my $self = shift;
    my %opt  = @_;
    $self->config( \%opt );
}

=head2 default_cap TYPE CLASS

Returns the default cap (if there is one) as specified by the config for
the given TYPE and CLASS.  Returns undef otherwise.

=cut

sub default_cap {
    my $self  = shift;
    my $type  = shift;
    my $class = shift;
    return $self->config->{$type}{$class};
}

1;
