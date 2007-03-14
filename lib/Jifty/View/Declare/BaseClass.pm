package Jifty::View::Declare::BaseClass;

use strict;
use warnings;
use base qw/Exporter Jifty::View::Declare::Helpers/;
use Scalar::Defer;
use Template::Declare::Tags;


use Jifty::View::Declare::Helpers;


our @EXPORT = ( @Jifty::View::Declare::Helpers::EXPORT);


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

