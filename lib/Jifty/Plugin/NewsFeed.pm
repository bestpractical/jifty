use warnings;
use strict;
package Jifty::Plugin::NewsFeed;
use base qw'Jifty::Plugin';

=head1 NAME

Jifty::Plugin::NewsFeed - Provide site news by feeds in your app

=head1 SYNOPSIS

# In your jifty config.yml under the framework section:

  Plugins:
    - NewsFeed: {}


=head1 DESCRIPTION

Provides templates to include site news feeds in your Jifty app. See L<Jifty::Plugin::NewsFeed::View>

=cut


1;
