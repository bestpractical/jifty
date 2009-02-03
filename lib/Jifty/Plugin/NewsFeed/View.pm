use warnings;
use strict;

package Jifty::Plugin::NewsFeed::View;
use Jifty::View::Declare -base;

=head1 NAME

Jifty::Plugin::NewsFeed::View - template for feed

=head1 DESCRIPTION

The templates for L<Jifty::Plugin::NewsFeed>

=cut

=head1 Templates

=head2 display_feed feed_url , {  title => TITLE , before => BEFORE , cache_ttl => TTL  , ... } 

display syndication feed

=head3 options

=over 4

=item title => I<string>  I<(optional)>

C<TITLE> , which overrides the title of feed.

=item before => I<string>  I<(optional)>

C<BEFORE>, is a range before current date, display feed items which were created before C<BEFORE> ago.
C<BEFORE> could be C<"7 days"> , C<"2 weeks"> , C<"1 months">

=item cache_ttl => I<integer>   I<(optional)>

C<TTL> (Time to live) for App::Cache.

=item hide_title => I<boolean>  I<(optional)>

hide feed title

=item max_items => I<integer>  I<(optional)>

max items to display.

=item order => I<string>  I<(optional)>

order feed items by date, 'DESC' or 'ASC'

=cut

template 'display_feed' => sub {
    my ( $self , $feed_url ) = @_;
    my $options = shift || {};

    return unless ( $feed_url =~ m(^https?://) );

    use XML::Feed;
    use App::Cache;
    use Encode qw(decode_utf8);

    my $cache = App::Cache->new({ ttl =>  $options->{cache_ttl} || 60*60   });
    my $feed_xml = $cache->get_url( $feed_url );

    my $feed = XML::Feed->parse ( \$feed_xml );

    unless ( $feed ) {
      h3 { "Can't Parse Feed" };
      div { { class is 'feed-error' };
          outs_raw( decode_utf8(XML::Feed->errstr) );
      };
      return;
    }

    my $feed_title = decode_utf8 ( $feed->title );

    my @entries = $feed->entries;

    # filter entry
    if( defined $options->{before} ) {
        my $before = $options->{before};
        my ( $num , $slice ) = ( $before =~ m/^(\d+)\s*(\w+)$/ );
        if( $num and $slice )  {
            my $theday = DateTime->now->subtract( $slice => $num );
            @entries = grep {  $_->issued > $theday  } @entries 
                                                            if ( $theday );
        } 
    }

    splice @entries,0,$options->{max_items}
            if( defined $options->{max_items} );

    @entries = reverse @entries 
            if( defined $options->{order} and $options->{order} eq 'ASC' );

    h2 { { class is 'feed-title' } ; $feed_title } 
            unless ( defined $options->{hide_title} );

    ul { { class is 'feed-entries' } ;
        for my $entry ( @entries ) {
            my $issued = $entry->issued;
            my $title = decode_utf8 ( $entry->title );
            my $summary = decode_utf8( $entry->summary );
            my $link  = $entry->link;

            li { { class is 'feed-entry' }; 
                outs_raw (qq|<a class="feed-link" href="$link">$title</a>|); } 
                    if ( $title );
        }
    };
};

1;
