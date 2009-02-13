use warnings;
use strict;
package Jifty::Plugin::NewsFeed;
use base qw'Jifty::Plugin';
__PACKAGE__->mk_accessors(qw(config));

=head1 NAME

Jifty::Plugin::NewsFeed - Provide site news by feeds in your app

=head1 SYNOPSIS

# In your jifty config.yml under the framework section:

  Plugins:
    - NewsFeed:
		CacheRoot: /tmp

# In your jifty application view

    template 'news' => page { title is 'News' } content  {
        show 'display_feed', 'http://path/to/feed', { max_items => 6 };
    };


=head1 DESCRIPTION

Provides templates to include site news feeds in your Jifty app. 
More detail about templates , see L<Jifty::Plugin::NewsFeed::View>


=head2 init

=cut

sub init {
    my $self = shift;
	$self->config( { @_ });
}

=head2 AUTHOR

Yo-An Lin ( Cornelius )

=cut


1;
