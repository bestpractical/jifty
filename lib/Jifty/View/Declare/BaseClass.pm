package Jifty::View::Declare::BaseClass;

use strict;
use warnings;
use base qw/Exporter Jifty::View::Declare::Helpers/;
use Scalar::Defer;
use Template::Declare::Tags;


use Jifty::View::Declare::Helpers;


our @EXPORT = ( @Jifty::View::Declare::Helpers::EXPORT);


sub use_mason_wrapper {
    my $class = shift;
    no strict 'refs';
    no warnings 'redefine';
    *{ $class . '::wrapper' } = sub ($) {
        my $code = shift;

        # so in td handler, we made jifty::web->out appends to td
        # buffer, we need it back for here someday we need to finish
        # fixing the output system that is in Jifty::View.
        local *Jifty::Web::out = sub { shift->mason->out(@_) };

        local *HTML::Mason::Request::content = sub {
            $code->();
            my $content = Template::Declare->buffer->data;
            Template::Declare->buffer->clear;
            $content;
        };

        Jifty->handler->fallback_view_handler->show('/_elements/wrapper');
        }
}

=cut



1;
__DATA__

=head1 NAME

Jifty::View::Declare::BaseClass

=head1 DESCRIPTION

This class provides a baseclass for your C<Template::Declare> derived view classes.


=head1 METHODS

=head2 use_mason_wrapper

Call this function in your viewclass to use your mason wrapper for TD templates.


=head2 show templatename arguments

Render a C<Template::Declare> template.


=cut

