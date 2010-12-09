package Jifty::View::Declare::BaseClass;

use strict;
use warnings;
use base qw/Exporter Jifty::View::Declare::Helpers/;

use Jifty::View::Declare::Helpers;


our @EXPORT = ( @Jifty::View::Declare::Helpers::EXPORT);

=head1 NAME

Jifty::View::Declare::BaseClass - Base class for Template::Declare views

=head1 DESCRIPTION

This class provides a base class for your L<Template::Declare> derived view classes.

=head1 METHODS

=head2 use_mason_wrapper

Call this function in your view class to use your mason wrapper for L<Template::Declare> templates,
something like:

    package TestApp::View;
    use Jifty::View::Declare -base;
    __PACKAGE__->use_mason_wrapper;

If you don't use mason then you can define a C<wrapper> function in the view class to override
default page layouts. Default TD wrapper defined in L<Jifty::View::Declare::Helpers>.

=cut

sub use_mason_wrapper {
    my $class = shift;
    no strict 'refs';
    no warnings 'redefine';
    *{ $class . '::wrapper' } = sub {
        my $code = shift;
        my $args = shift || {};

        my $interp = Jifty->handler->view('Jifty::View::Mason::Handler')->interp;
        my $req = $interp->make_request( comp => '/_elements/wrapper' );
        my $wrapper = $interp->load("/_elements/wrapper");
        local $HTML::Mason::Commands::m = $req;
        $req->comp(
            {content => sub {$code->()}},
            $wrapper,
            %{$args}
        );
    }
}

use Attribute::Handlers;
our (%Static, %Action);

=head1 ATTRIBUTES

clkao owes documentation as to the meaning of this and when it would be acceptable to use it.

=head2 Static

TODO Document this...

This is part of the client-caching system being developed for Perl to allow you to translate templates into JavaScript running on the client.

This function allows a developer to mark a L<Template::Declare> template as static (unchanging), so that the compiled version can be cached on the client side and inserted with javascript.

=cut

sub Static :ATTR(CODE,BEGIN) { $Static{$_[2]}++; }

=head2 Action

TODO Document this...

This is part of the client-caching system being developed for Perl to allow you to translate templates into JavaScript running on the client.

This function allows a developer to mark a Template::Declare template as an action.

=cut

sub Action :ATTR(CODE,BEGIN) { $Action{$_[2]}++; }

=head1 SEE ALSO

L<Jifty::View::Declare>, L<Template::Declare>, L<Jifty::View::Declare::Helpers>

=head1 LICENSE

Jifty is Copyright 2005-2010 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
