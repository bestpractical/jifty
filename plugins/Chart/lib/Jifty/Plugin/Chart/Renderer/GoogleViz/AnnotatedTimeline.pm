package Jifty::Plugin::Chart::Renderer::GoogleViz::AnnotatedTimeline;
use strict;
use warnings;
use base 'Jifty::Plugin::Chart::Renderer::GoogleViz';

use constant packages_to_load => 'annotatedtimeline';
use constant chart_class => 'google.visualization.AnnotatedTimeLine';
use constant draw_params => {
    displayAnnotations => "true",
};

1;

