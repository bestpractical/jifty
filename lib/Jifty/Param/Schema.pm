package Jifty::Param::Schema;

=head1 NAME

Jifty::Param::Schema - Declare parameters of a Jifty action with ease.

=head1 SYNOPSIS

    package Wifty::Action::Login;
    use Jifty::Param::Schema;
    use Jifty::Action schema {

    param email =>
        label is 'Email address',
        is mandatory,
        ajax validates;

    param password =>
        type is 'password',
        label is 'Password',
        is mandatory;

    param remember =>
        type is 'checkbox',
        label is 'Remember me?',
        hints is 'If you want, your browser can remember your login for you'
        default is 0;

    };

=head1 DESCRIPTION

This module provides a simple syntax to declare action parameters.

It re-exports C<defer> and C<lazy> from L<Scalar::Defer>, for setting
parameter fields that must be recomputed at request-time.

=head2 schema

The C<schema> block from a L<Jifty::Action> subclass describes an action
for a Jifty application.

Within the C<schema> block, the localization function C<_> is redefined
with C<defer>, so that it resolves into a dynamic value that will be
recalculated upon each request, according to the user's current language
preference.

=head2 param

Each C<param> statement inside the C<schema> block sets out the name
and attributes used to describe one named parameter, which is then used
to build a L<Jifty::Param> object.  That class defines possible field names
to use in the declarative syntax here.

The C<param> function is not available outside the C<schema> block.

=head1 SEE ALSO

L<Object::Declare>, L<Scalar::Defer>

=cut

use strict;
use warnings;
use Jifty::I18N;
use Jifty::Param;
use Scalar::Defer;
use Object::Declare (
    mapping => {
        param => 'Jifty::Param',
    },
    copula  => {
        is      => '',
        are     => '',
        ajax    => 'ajax_',
    }
);
use Exporter::Lite;
use Class::Data::Inheritable;

our @EXPORT = qw( defer lazy param schema );

sub schema (&) {
    my $code = shift;
    my $from = caller;

    no warnings 'redefine';
    local *_ = sub { my $args = \@_; defer { _(@$args) } };

    Class::Data::Inheritable::mk_classdata($from => qw/PARAMS/);
    my @params = &declare($code);
    my $count = 1; # Start at 1, increment by 10
    foreach my $param (@params) {
        next if !ref($param) or defined($param->sort_order);
        $param->sort_order($count);
        $count += 10;
    }

    if ($from->can('SUPER::PARAMS')) {
        unshift @params, %{ $from->can('SUPER::PARAMS')->() || {} }
    }

    $from->PARAMS({ @params });

    no strict 'refs';
    push @{$from . '::ISA'}, 'Jifty::Action';
    return;
}

1;
