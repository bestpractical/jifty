use warnings;
use strict;

package Jifty::Plugin::NewsFeed::View;
use Jifty::View::Declare -base;

=head1 NAME

Jifty::Plugin::NewsFeed::View - template for feed

=head1 DESCRIPTION

The templates for L<Jifty::Plugin::NewsFeed>

=head1 SYNOPSIS

    div { { class is 'feed-wrapper' };
        show 'display_feed' , 'http://example.com/feed/default' , { before => '7days' };
    };

=head1 Templates

=head2 display_feed FEED_URL , {  title => TITLE , before => BEFORE , cache_ttl => TTL  , ... } 

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

=item style => I<string>  I<(optional)>

style could be 'list', 'p' , 'none' , default is 'list'.

=cut

template 'display_feed' => sub {
    my $self     = shift;
    my $feed_url = shift;
    my $options  = shift || {};

    return unless ( $feed_url and $feed_url =~ m(^https?://) );

    use XML::Feed;
    use Encode qw(decode_utf8);
	use Cache::File;

	my $plugin = Jifty->find_plugin( 'Jifty::Plugin::NewsFeed' );
	warn $plugin->config->{CacheRoot};


	my $c1 = Cache::File->new( cache_root =>  $plugin->config->{CacheRoot}  );
	my $feed_xml = $c1->get( 'feed_url' );
 	unless ($feed_xml) {
		use LWP::Simple;
		Jifty->log->info('Fetch feed:' . $feed_url );
 		$feed_xml = get $feed_url;
 		$c1->set( 'feed_url' , $feed_xml , '1 hours' );
 	}

    my $feed = XML::Feed->parse ( \$feed_xml );

    unless ( $feed ) {
      h3 { "Can't Parse Feed" };
      div { { class is 'feed-error' };
          outs_raw( decode_utf8(XML::Feed->errstr) );
      };
      return;
    }

    my $feed_title = $options->{title} || decode_utf8 ( $feed->title );

    my @entries = $feed->entries;

    return unless ( @entries );

    # filter entry
    if( defined $options->{before} ) {
        my $before = $options->{before};
        my ( $num , $slice ) = ( $before =~ m/^(\d+)\s*(\w+)$/ );
        if( $num and $slice )  {
            my $theday = DateTime->now->subtract( $slice => $num );
            @entries = grep {  $_->issued > $theday  } @entries ;
            #  if ( $theday );
        } 
    }

    @entries = splice @entries,0,$options->{max_items}
            if( defined $options->{max_items} );

    @entries = reverse @entries 
            if( defined $options->{order} and $options->{order} eq 'ASC' );

    my $style = $options->{style} || 'list';

    h2 { { class is 'feed-title' } ; $feed_title } 
            unless ( defined $options->{hide_title} );

    if( $style eq 'list' ) {
        show 'feed_list_style',\@entries;
    }
    elsif( $style eq 'p' ) {
        show 'feed_p_style',\@entries;
    }
    elsif( $style eq 'none' ) {
        show 'feed_none_style',\@entries;
    }
    else {
        show 'feed_list_style',\@entries;
    }
 
};

template 'feed_list_style' => sub {
    my $self = shift;
    my @entries = @{ +shift };
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

template 'feed_p_style' => sub {
    my $self = shift;
    my @entries = @{ +shift };
    for my $entry ( @entries ) {
        my $issued = $entry->issued;
        my $title = decode_utf8 ( $entry->title );
        my $summary = decode_utf8( $entry->summary );
        my $link  = $entry->link;

        p { { class is 'feed-entry' }; 
            outs_raw (qq|<a class="feed-link" href="$link">$title</a>|); } 
                if ( $title );
    }
};

template 'feed_none_style' => sub {
    my $self = shift;
    my @entries = @{ +shift };
    for my $entry ( @entries ) {
        my $issued = $entry->issued;
        my $title = decode_utf8 ( $entry->title );
        my $summary = decode_utf8( $entry->summary );
        my $link  = $entry->link;

        span { { class is 'feed-entry' }; 
            outs_raw (qq|<a class="feed-link" href="$link">$title</a>|); } 
                if ( $title );
    }
    
};




1;
