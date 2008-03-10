use strict;
use warnings;

package Jifty::Plugin::Comment::Notification::CommentNeedsModeration;
use base qw/ Jifty::Notification /;

__PACKAGE__->mk_accessors(qw/ comment parent /);

=head1 NAME

Jifty::Plugin::Comment::Notification::CommentNeedsModeration - new comments made, but not published

=head1 SYNOPSIS

To activate this notification, you must override the notification in your application.

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

  sub url {
      my $self = shift;
      return Jifty->config->framework('Web')->{'BaseURL'}
          . $self->parent->permalink
          . '#comment-'.$self->comment->id;
  }

  1;

=head1 DESCRIPTION

This notificaiton (when properly configured) is sent out to any who need to know when a comment has been created, but not published because L<Net::Akismet> has marked it as spam.

=head1 METHODS

=head2 setup

This method sets up the notification. This method should be overridden to setup L<Jifty::Notification/to_list> to select who will receive this message. See the L</SYNOPSIS>.

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

=head2 comment

This will contain the L<Jifty::Plugin::Comment::Model::Comment> that has been published.

=head2 parent

This will contain the object that the comment has been attached to.

=head2 url

THis returns the URL that the message will link to. This should be overridden to provide application-specific URLs. The default implementation returns the BaseURL setting for the application.

=cut

sub url {
    my $self = shift;
    return Jifty->config->framework('Web')->{'BaseURL'};
}

=head1 SEE ALSO

L<Jifty::Notification>, L<Jifty::Plugin::Comment::Notification::CommentPublished>

=head1 AUTHOR

Andrew Sterling Hanenkamp, C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
