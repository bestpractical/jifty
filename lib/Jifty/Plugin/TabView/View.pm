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

     # more flexible tabs
     $self->render_tabs('foo', [qw(id)],
                        { label => 'This is foo 1', path => 'foo', name => 'foo 1', args => { id => 1}},
                        { label => 'This is foo 2', path => 'foo', name => 'foo 2', defer => 1,  args => { id => 2}});

  };
  template 'foo' => sub { ... };
  template 'bar' => sub { ... };

=head2 render_tabs

Returns some Template::Declare with tabs rendered with the yui tabs
If a tab ends in _tab, it means it should contain a stub region to be
replaced by the corresponding fragment onclick to that tab.

=cut

sub _tab_path {
    my ($self, $name) = @_;
   
    # If the path is already relative or absolute, don't force-relativeize it
    my $qualified_path = ($name =~ qr|\.?/|) ? $name : "./$name";

    $self->can('fragment_for') ? $self->fragment_for($name) : $qualified_path;
}

sub render_tabs {
    my ($self, $divname, $args, @tabs) = @_;

    outs_raw(qq'<script type="text/javascript">
	var myTabs = new YAHOO.widget.TabView("$divname");
	</script>'  );

    @tabs = map { ref($_) ? $_
		      : do {
			  my $path = $_;
			  my $defer = $path =~ s/_tab$//;
			  { path => $path,
			    defer => $defer };
			  }
		  } @tabs;

    $_->{name} ||= $_->{path}, $_->{label} ||= $_->{path} for @tabs;

    div { { id is $divname, class is 'yui-navset'}
	  ul { { class is 'yui-nav'};
	       my $i = 0;
	       for my $tab (@tabs) {
		   li { { class is 'selected' unless $i };
			hyperlink(url => '#tab'.++$i, label => $tab->{label},
				  $tab->{defer} ?
				  (onclick =>
				  { region       => Jifty->web->current_region ? Jifty->web->current_region->qualified_name."-$tab->{name}-tab" : "$tab->{path}-tab",
				    replace_with => _tab_path($self, $tab->{path}), # XXX: should have higher level function handling mount point
				    args => { (map { $_ => get($_)} @$args ), %{$tab->{args} || {}} },
				  }) : ()
				 ) }
	       }
	   };
	  div { {class is 'yui-content' };
		my $default_shown;
		for my $tab (@tabs) {
		    div {
			if ($tab->{defer}) {
			    render_region(name => $tab->{name}.'-tab',
                          ($default_shown++)? () : ( path => _tab_path($self, $tab->{path}),
						     force_arguments => { ( map { $_ => get($_)} @$args ), %{$tab->{args} || {}} } )
                          )
			}
			else {
			    show( _tab_path($self, $tab->{path}) );
			    $default_shown++;
			}
		    }
		}
	    }
      };
};

1;
