package Jifty::View::Declare::BaseClass;

use strict;
use warnings;
use vars qw( $r );
use base qw/Exporter Jifty::View::Declare::Helpers/;
use Scalar::Defer;
use Template::Declare::Tags;
use Jifty::View::Declare::Helpers;

our @EXPORT = (
    @Jifty::View::Declare::Helpers::EXPORT,
    @Template::Declare::Tags::EXPORT,
);

{
    no warnings 'redefine';

    sub show {
        # Handle relative path here!

        my $path = shift;
        $path =~ s{^/}{};
        Jifty::View::Declare::Helpers->can('show')->( $path, @_ );
    }
}



1;
__DATA__

=head1 NAME

Jifty::View::Declare::BaseClass

=head1 DESCRIPTION

This class provides a baseclass for your C<Template::Declare> derived view classes.


=head1 METHODS

=head2 show templatename arguments

Render a C<Template::Declare> template.


=cut

=cut
