package Jifty::Plugin::TabView::View;
use strict;
use warnings;

# XXX: To be converted to a plugin with included css and images.

use Jifty::View::Declare -base;

use base 'Exporter';
our @EXPORT = qw(render_tabs);

=head1 NAME

Jifty::Plugin::TabView::View - render tabview using yui tabs

=head1 SYNOPSIS

  use Jifty::Plugin::TabView::View;
  template 'index.html' => page {
     my $self = shift;
     $self->render_tabs('foo', [qw(id)], qw( foo bar_tab ) );
  };
  template 'foo' => sub { ... };
  template 'bar' => sub { ... };

=head2 render_tabs

Returns some Template::Declare with tabs rendered with the yui tabs
If a tab ends in _tab, it means it should contain a stub region to be
replaced by the corresponding fragment onclick to that tab.

=cut

sub render_tabs {
    my ($self, $divname, $args, @tabs) = @_;

    outs_raw(qq'<script type="text/javascript">
	var myTabs = new YAHOO.widget.TabView("$divname");
	</script>'  );


    div { { id is $divname, class is 'yui-navset'}
	  ul { { class is 'yui-nav'};
	       my $i = 0;
	       for (@tabs) {
		   my $tab = $_;
		   li { { class is 'selected' unless $i };
			hyperlink(url => '#tab'.++$i, label => $tab,
				  $tab =~ s/_tab$// ? 
				  (onclick =>
				  { region       => Jifty->web->current_region->qualified_name."-$tab-tab",
				    replace_with => $self->fragment_for($tab),
				    args => { map { $_ => get($_)} @$args },
				  }) : ()
				 ) }
	       }
	   };
	  div { {class is 'yui-content' };
		for (@tabs) {
		    div { 
			if (s/_tab$//) {
			    render_region(name => $_.'-tab');
			}
			else {
			    die "$self $_" unless $self->has_template($_);
			    $self->has_template($_)->(); 
			}
		    }
		}
	    }
      };
};

1;
