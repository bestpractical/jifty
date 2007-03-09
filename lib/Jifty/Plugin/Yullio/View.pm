package Jifty::Plugin::Yullio::View;
use strict;
use warnings;

# XXX: To be converted to a plugin with included css and images.

use Jifty::View::Declare -base;

use base 'Exporter';
our @EXPORT = qw(yullio);

=head1 NAME

Jifty::Plugin::Yullio::View - Yullio layout bundles

=head1 SYNOPSIS

  use Jifty::Plugin::Yullio::View;
  template 'index2.html' => page {
    with ( width => 'doc2', column_template => 'yui-t6' ),
    yullio
     { outs('This is main content') }
     sub { outs('This is something on the side') } };

=head1 DESCRIPTION

C<Jifty::Plugin::Yullio::View> provides an alternative C<page>
temlpate constructor that makes use of yui grid layouts.

=cut

sub _yullio_content {
    my ($code1, $code2) = @_;
    # XXX: fix get_current_attr with multiple arguments
    my ($width, $column_template) = map {get_current_attr($_)}
	qw(width column_template);
    sub {
	# XXX: T::D is propagating our with to deeper callstacks as we
	# are not calling from "_tag"
	with (),


	div {
	    { id is $width, class is $column_template }

	    div { { id is 'hd' }
		  div { { id is 'yui-main' }
		        div { { class is 'yui-b' }
                              div { { id is 'content' }
                                    $code1->() } } };
                  if ($column_template ne 'yui-t7') {
		      div { { id is 'yui-b' }
                            div { { id is 'utility' }
                                  $code2->() } }
		  } } }
    };
}

sub yullio(&&) {
    my ($code1, $code2) = @_;
    _yullio_content($code1, $code2)->();
}

1;

