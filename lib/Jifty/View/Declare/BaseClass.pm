package Jifty::View::Declare::BaseClass;

use strict;
use warnings;
use base qw/Exporter Jifty::View::Declare::Helpers/;
use Scalar::Defer;
use Template::Declare::Tags;


use Jifty::View::Declare::Helpers;


our @EXPORT = ( @Jifty::View::Declare::Helpers::EXPORT);

=head1 NAME

Jifty::View::Declare::BaseClass - Base class for Template::Declare views

=head1 DESCRIPTION

This class provides a base class for your L<Template::Declare> derived view classes.

=head1 METHODS

=head2 use_mason_wrapper

Call this function in your view class to use your mason wrapper for L<Template::Declare> templates.

=cut

sub use_mason_wrapper {
    my $class = shift;
    no strict 'refs';
    no warnings 'redefine';
    *{ $class . '::wrapper' } = sub {
        my $code = shift;
        my $args = shift;
        # so in td handler, we made jifty::web->out appends to td
        # buffer, we need it back for here before we call $code.
        # someday we need to finish fixing the output system that is
        # in Jifty::View.
        my $td_out = \&Jifty::Web::out;
        local *Jifty::Web::out = sub { shift->mason->out(@_) };

        local *HTML::Mason::Request::content = sub {
            local *Jifty::Web::out = $td_out;
            $code->();
            my $content = Template::Declare->buffer->data;
            Template::Declare->buffer->clear;
            $content;
        };

        Jifty->handler->fallback_view_handler->show('/_elements/wrapper', $args);
    }
}

use Attribute::Handlers;
our %Static;
sub Static :ATTR(CODE,BEGIN) {
    $Static{$_[2]}++;
}

our %Action;
sub Action :ATTR(CODE,BEGIN) {
    $Action{$_[2]}++;
}

=head2 show templatename arguments

Render a C<Template::Declare> template.

=head1 SEE ALSO

L<Template::Declare>, L<Jifty::View::Declare::Helpers>, L<Jifty::View::Declare>

=head1 LICENSE

Jifty is Copyright 2005-2007 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
