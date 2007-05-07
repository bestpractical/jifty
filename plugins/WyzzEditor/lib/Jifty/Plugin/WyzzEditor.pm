use strict;
use warnings;

package Jifty::Plugin::WyzzEditor;
use base qw/Jifty::Plugin/;

=head1 SYNOPSIS

In etc/config.yml

   Plugins:
     - WyzzEditor: {}

In your Model instead of 

   render_as 'teaxterea';

use

  render_as 'Jifty::Plugin::WyzzEditor::Textarea';


In your View 

  Jifty->web->link( 
    label   => _("Save"), 
    onclick => [
      { beforeclick =>
          "updateTextArea('".$action->form_field('myfield')->element_id."');" },
      { args => .... }
    ]
  );

=head1 DESCRIPTION

Wyzz, simple WYSIWYG online editor usable in fragments

=cut


sub init {
	my $self = shift;
	Jifty->web->javascript_libs([
	@{ Jifty->web->javascript_libs },
	"wyzz.js",
	]);
}

1;
