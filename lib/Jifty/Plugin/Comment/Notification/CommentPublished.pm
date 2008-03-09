use strict;
use warnings;

package Jifty::Plugin::Comment::Notification::CommentPublished;
use base qw/ Jifty::Notification /;

__PACKAGE__->mk_accessors(qw/ comment parent /);

=head1 DESCRIPTION

If you want to receive these notifications, you must override L</setup> to set your the C<to_list> for your application.

  use strict;
  use warnings;

  package MyApp::Notification::CommentPublished;
  use base qw/ Jifty::Plugin::Comment::Notification::CommentPublished /;

  sub setup {
      my $self = shift;

      # Send to the author of the post
      $self->to_list($self->parent->author);

      $self->SUPER::setup(@_);
  }

  1;

=cut

sub setup {
    my $self = shift;

    my $appname = Jifty->config->framework('ApplicationName');
    my $comment = $self->comment;

    my $from = $comment->your_name || 'Anonymous Coward';
    $from .= ' <'.$comment->email.'>' if $comment->email;
    $from .= ' ('.$comment->web_site.')'      if $comment->web_site;

    my $url = $self->url;

    $self->subject(_("[%1] New comment: %2", $appname, $comment->title));
    $self->body(_("
View Comment: %1

On Post: %2
Subject: %3
From: %4
Date: %5

%6
", 
        $url,
        $self->parent->title,
        $comment->title, 
        $from, 
        $comment->created_on->strftime('%A, %B %d, %Y @ %H:%M%P'), 
        $comment->body
    ));
}

sub url {
    my $self = shift;
    return Jifty->config->framework('Web')->{'BaseURL'};
}

1;
