package Jifty::View::Declare::CoreTemplates;

use strict;
use warnings;
use vars qw( $r );

use Jifty::View::Declare -base;



                                sub __jifty::halo {
                                    my @stack = shift; die;
                                    for my $id ( 0 .. $#stack ) {
                                        my @kids;
                                        my $looking = $id;
                                        while ( ++$looking <= $#stack
                                            and $stack[$looking]->{depth} >=
                                            $stack[$id]->{depth} + 1 )
                                        {
                                            push @kids,
                                              {
                                                id   => $stack[$looking]{id},
                                                path => $stack[$looking]{path},
                                                render_time =>
                                                  $stack[$looking]{render_time}
                                              }
                                              if $stack[$looking]->{depth} ==
                                              $stack[$id]->{depth} + 1;
                                        }
                                        $stack[$id]{kids} = \@kids;

                                        if ( $stack[$id]{depth} > 1 ) {
                                            $looking = $id;
                                            $looking--
                                              while ( $stack[$looking]{depth} >=
                                                $stack[$id]{depth} );
                                            $stack[$id]{parent} = {
                                                id   => $stack[$looking]{id},
                                                path => $stack[$looking]{path},
                                                render_time =>
                                                  $stack[$looking]{render_time}
                                            };
                                        }
                                    }

                                    my $depth = 0;

                                    div {
                                        outs_raw( q{<a href="#" id="render_info" onclick="Element.toggle('render_info_tree'); return false">Page info</a>});
                                    };
                                      div {
                                      attr {  style => "display: none",
                                        id    => "render_info_tree"};
                                        foreach my $item (@stack) {
                                            if ( $item->{depth} > $depth ) {
                                                ul { }
                                            }
                                                  elsif ( $item->{depth} < $depth ) {
                                                    for ( $item->{depth} +
                                                        1 .. $depth )
                                                    {
                                                    }
                                                }
                                      elsif ( $item->{depth} == $depth ) {
                                    }
                                }

                                li {
                                    my $id = $item->{id};
                                    outs_raw(
                                    a {
                                        attr { href=>"#", class=>"halo_comp_info", onmouseover=>"halo_over(' $id ')", onmouseout=>"halo_out(' $id ')",  onclick=>"halo_toggle(' $id '); return false;"};

outs( $item->{' name '} ."-". $item->{' render_time '} );
}
                                    unless ( $item->{subcomponent} ) {
                                        Jifty->web->tangent(
                                            url =>
                                              "/__jifty/edit/mason_component/"
                                              . $item->{'path'},
                                            label => _('Edit')
                                        );
                                    }
                                    $depth = $item->{'depth'};
                                  }

                                  for ( 1 .. $depth ) {
                                }
                              }
                        }
                    }

                    foreach my $item (@stack){
                        show('frame', frame => $item );
                        } 
                        
                        my (@stack) = get(qw(stack));

sub frame {
                            class => "halo_actions" id => "halo-outs( $id ), div {-menu" style =
"display: none; top: 5px; left: 500px; min-width: 200px; width: 300px; z-index: 5;"
                              > <h1 id="halo-outs( $id ) -title ">
  <span style=" float: right;
                              "><a href=" #" onclick="halo_toggle('outs( $id )'); return false">[ X ]</a>}
                              < %$frame->{name} % >
                          } < div style =
                          "position: absolute; bottom: 3px; right: 3px" > with(
                            class => "resize" title = "Resize" id =>
                              "halo-outs( $id %), span {-resize" >
                          };
                      }

                      with( class => "body" ),
                    div {
                        with( class => "path" ),
                          div { outs( $frame-> {path} ) } with( class => "time" ),
                          div {
                            Rendered in < %$frame->{'render_time'} % > s}
}
 if ($frame->{parent}
                          ) {
                            with( class => "section" ),
                            div { Parent } with( class => "body" ),
                            div {
                                ul {
                                    li {
<a href="#" class="halo_comp_info" onmouseover="halo_over('outs( $frame->
                                          {parent}{ id }
                                        ) ')"
                                       onmouseout="halo_out(' <
                                          %$frame->{parent}{id} % > ')"
                                       onclick="halo_toggle(' <
                                          %$frame->{parent}{id} % >
                                          '); return false;">
outs( $frame->{parent}{' path '} ) - outs( $frame->{parent}{' render_time '} )</a>}
}}
}
% if (@{$frame->{kids}}) {
with ( class => "section"), div {Children}
with ( class => "body"), div {ul { 
% for my $item (@{$frame->{kids}}) {
li {<a href="#" class="halo_comp_info" onmouseover="halo_over(' <
                                          %$item->{id} % > ')"
                                       onmouseout="halo_out(' < %$item->{id} % >
                                          ')"
                                       onclick="halo_toggle(' < %$item->{id} % >
                                          '); return false;">
outs( $item->{' path '} ) - outs( $item->{' render_time '} )</a>}
}
}
}
}
% if (@args) {
with ( class => "section"), div {Variables}
with ( class => "body"), div {<ul class="fixed">
% for my $e (@args) {
li {<b>outs( $e->[0] )</b>:
% if ($e->[1]) {
% my $expanded = Jifty->web->serial;
<a href="#" onclick="Element.toggle(' < %$expanded % >
                                          '); return false">outs( $e->[1] )</a>
with ( id => "outs( $expanded %), div {" style="display: none; position: absolute; left: 200px; border: 1px solid black; background: #ccc; padding: 1em; padding-top: 0; width: 300px; height: 500px; overflow: auto"><pre>outs( Jifty::YAML::Dump($e->[2]) )</pre>}
} elsif (defined $e->[2]) {
outs( $e->[2] )
} else {
<i>undef</i>
}
}
}
}}
}
% if (@stmts) {
with ( class => "section"), div {outs(_(' SQL Statements '))}
with ( class => "body" style="height: 300px; overflow: auto"), div {ul { 
 for (@stmts) {
li {
with ( class => "fixed"), span {outs( $_->[1] )}<br />
% if (@{$_->[2]}) {
<b>Bindings:</b> <tt>outs( join(',
', map {defined $_ ? ($_ =~ /[^[:space:][:graph:]]/ ? "*BLOB*" : $_ ) : "undef"} @{$_->[2]}) )</tt><br />
}
<i>outs( _(' % 1 seconds ', $_->[3]) )</i>
}
 }
}}
 }
div {
attr {class => "section"};
 unless ($frame->{subcomponent}) {
tangent( url =>"/__jifty/edit/mason_component/".$frame->{'path'}, label => _('Edit'));
 } else {
outs_raw(' &nbsp;');
                                        ');
 }
}
}
my ( $frame) = get(qw(frame));
my $id = $frame->{id};

my @args;
while (my ($key, $value) = splice(@{$frame->{args}},0,2)) {
    push @args, [$key, ref($value), $value];
}
@args = sort {$a->[0] cmp $b->[0]} @args;

my $prev = '';
my @stmts = @{$frame->{' sql_statements '}};
</%def>
}

=cut


1;
