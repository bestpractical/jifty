package Jifty::Module::Pluggable;
use strict;
use warnings;
use base qw/Module::Pluggable/;

=head1 NAME

Jifty::Module::Pluggable - Jifty-specific helper for Module::Pluggable


=head1 DESCRIPTION

A custom subclass of Module::Pluggable to override the C<require>
mechanism with one that better fits our own view of the world.

=head2 require

    Date:   October 24, 2006 12:19:31 AM PDT
    From:     simon@thegestalt.org
    Subject:    Re: Module::Pluggable and CORE::require
    To:       jesse@bestpractical.com

On Mon, Oct 23, 2006 at 09:11:22PM -0700, Jesse Vincent said:
does this thread make any sense to you? It looks like
Module::Pluggable is interacting poorly with UNIVERSAL::require?

Module::Pluggable used to to use UNIVERSAL::require but I switched
because I was trying to get rid of dependencies.

I farmed the requiring stuff off to it's own _require method in order to
make it easy to subclass so that people could override how the require
was done.


=head3  But Simon is lying...

What we actually need to override is Module::Pluggable::Object::_require, which we do below.


=cut


use Module::Pluggable::Object;
use UNIVERSAL::require;

no warnings 'redefine';
sub Module::Pluggable::Object::_require {
    my $self = shift;
    my $module = shift;

    # Module::Pluggable::Object::_require expects a true value (the error message) on failure
    # On success, it expects you to return undef.

    return if $module =~/\.#/;
    eval { Jifty::Util->require($module); };
    my $err = $@;
    return $err;
}

1;
