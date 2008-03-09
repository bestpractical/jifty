use strict;
use warnings;

package Jifty::Plugin::Comment::Notification::CommentNeedsModeration;
use base qw/ Jifty::Notification /;

__PACKAGE__->mk_accessors(qw/ comment parent /);

=head1 DESCRIPTION

If you want to receive these notifications, you must override L</setup> to set your the C<to_list> for your application.

  use strict;
  use warnings;

  package MyApp::Notification::CommentNeedsModeration;
  use base qw/ Jifty::Plugin::Comment::Notification::CommentNeedsModeration /;

  sub setup {
      my $self = shift;

      # Limit to users that have a "moderator" column set to 1
      my $users = MyApp::Model::UserCollection->new;
      $users->limit( column => 'moderator', value => 1 );
      $self->to_list(@{ $users->items_array_ref });

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

    $self->subject(_("[%1] Moderate comment: %2", $appname, $comment->title));
    $self->body(_(q{
The following comment has not been published. If you would like to publish it, please visit the link below and click on the "publish" link. If it has been marked as spam and should not have been you should also click on the "mark as ham" link.

View Comment: %1

On Post: %2
Subject: %3
From: %4
Date: %5

%6
}, 
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
