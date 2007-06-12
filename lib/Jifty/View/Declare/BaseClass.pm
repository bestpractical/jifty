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
    *{ $class . '::wrapper' } = sub ($) {
        my $code = shift;
	no warnings 'redefine';
        # so in td handler, we made jifty::web->out appends to td
        # buffer, we need it back for here, because $code is actually
        # called.  someday we need to finish fixing the output system
        # that is in Jifty::View.
        my $td_out = \&Jifty::Web::out;
        local *Jifty::Web::out = sub { shift->mason->out(@_) };

        Jifty->handler->fallback_view_handler->interp->autoflush(1);
        local *HTML::Mason::Request::content
            = sub { local *Jifty::Web::out = $td_out; $code; '' };
        Jifty->web->request->arguments->{title} = 'YADA!';
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

