package Jifty::CAS;
use strict;

=head1 NAME

Jifty::CAS - Jifty's Content-addressable storage facility

=head1 SYNOPSIS

  my $key = Jifty::CAS->publish('js' => 'all', $content,
                      { hash_with => $content, # default behaviour
                        content_type => 'application/x-javascript',
                        deflate => 1
                      });

  $ie_key = Jifty::CAS->publish('js' => 'ie-only', $ie_content,
                      { hash_with => $ie_content,
                        content_type => 'application/x-javascript',
                      });

  $key = Jifty::CAS->key('js', 'ie-only');
  my $blob = Jifty::CAS->retrieve('js', $key);

=head1 DESCRIPTION



=cut

my %CONTAINER;

use Digest::MD5 'md5_hex';
use Compress::Zlib ();

sub publish {
    my ($class, $domain, $name, $content, $opt) = @_;
    my $db = $CONTAINER{$domain} ||= {};

    my $key = md5_hex( delete $opt->{hash_with} || $content );
    $db->{DB}{$key} = Jifty::CAS::Blob->new
        ( { content => $content,
            metadata => $opt } );
    $db->{KEYS}{$name} = $key;

    return $key;
}

sub key {
    my ($class, $domain, $name) = @_;
    return $CONTAINER{$domain}{KEYS}{$name};
}

sub retrieve {
    my ($class, $domain, $key) = @_;
    return $CONTAINER{$domain}{DB}{$key};
}

package Jifty::CAS::Blob;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(content content_deflated metadata));

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->content_deflated(Compress::Zlib::memGzip($self->content)) if $self->metadata->{deflate};
    return $self;
}

1;
