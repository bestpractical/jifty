use strict;
use warnings;

package Jifty::Plugin::CodePress;
use base qw/Jifty::Plugin/;

=head1 NAME

Jifty::Plugin::CodePress

=head1 DESCRIPTION

CodePress, web-based source code editor with syntax highlighting

=head1 SYNOPSIS

In etc/config.yml

  Plugins:
    - CodePress: {}

In your View do something like:

  $action->form_field( 'source',
	cols => 80, rows => 25,
	language => 'perl',
	render_as => 'Jifty::Plugin::CodePress::Textarea',
  );

  Jifty->web->submit( 
	label   => _("Save"), 
    onclick => [
      { beforeclick => "CodePress.beforeSubmit();" },
      { args => .... }
    ]
  );

or if you are using L<Template::Declare>

  render_param(
  	$action => 'source',
	cols => 80, rows => 25,
	language => 'perl',
	render_as => 'Jifty::Plugin::CodePress::Textarea',
  );

  form_submit(
	label => _("Save"),
	onclick => [
		{ beforeclick => "CodePress.beforeSubmit();" },
		{ args => .... },
	],
  );

=head1 VERSION

Created from L<https://codepress.svn.sourceforge.net/svnroot/codepress/trunk/stable>
revision 219 with bunch of local changes to make it play nicer with Jifty.

This involved some hard-coding of paths (because automatic path detection
from CodePress doesn't work well with Jifty's expectation of JavaScript code
in C</js/>), addition of C<CodePress.instances> object to track all
instances and CodePress.beforeSubmit which prepare form for submission.

This also side-stepped problem with original calling schematic which created
functions with names from element ids. This was problematic with Jifty
because ids are automatically generated and use dashes (C<->) in them which
aren't valid JavaScript function names.

=head1 BUGS

There seems to strange interaction between CodePress and Jifty fragments.

=head1 SEE ALSO

L<http://codepress.org/> - project site

=cut

sub init {
	my $self = shift;
	Jifty->web->javascript_libs([
	@{ Jifty->web->javascript_libs },
	"codepress.js",
	]);
}

1;
