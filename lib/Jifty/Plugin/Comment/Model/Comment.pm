use strict;
use warnings;

package Jifty::Plugin::Comment::Model::Comment;
use Jifty::DBI::Schema;

use constant CLASS_UUID => '7B703CCA-544E-11DC-9227-2E96D84604BE';

=head1 NAME

Jifty::Plugin::Comment::Model::Comment - comments attached to anything

=head1 SYNOPSIS

  # to customize...
  package App::Model::Comment;
  use base qw/ Jifty::Plugin::Comment::Model::Comment /;

  use Jifty::DBI::Schema;
  use App::Record schema {
      # Add a reference to the current user that creates this comment
      column by_user =>
          references App::Model::User,
          ;
  };

  # make it so that any logged user can comment, but anyone can view, except
  # that we don't really want everyone seeing all those personal bits...
  sub current_user_can {
      my $self = shift;
      my ($right, %args) = @_;

      if ($right eq 'create') {
          return 1 if $self->current_user->id;
      }

      if ($right eq 'read') {
          return $self->published
              unless $args{column} =~ /^ 
                  (?: email
                    | status
                    | ip_addr
                    | http_refer
                    | http_user_agent ) $/x;
      }

      # otherwise only superuser gets in
      return $self->SUPER::current_user_can(@_);
  }

=head1 DESCRIPTION

This model is the repository for all comments in your application, if you use the L<Jifty::Plugin::Comment> plugin.

=head1 SCHEMA

=head2 title

This is the title of the comment.

=head2 body

This is the body of the comment.

=head2 created_on

This is the timestamp of when the comment was created.

=head2 your_name

This is the name the author of the comment has claimed.

=head2 web_site

This is the name of the web site the author claims as her own.

=head2 email

This is the email address the author is claiming.

=head2 published

This is a boolean flag indicating whether the comment should be shown or not when viewed.

=head2 status

This is a flag containing one of two values: "spam" or "ham". It indicates whether the comment has been evaluated as spam or not by L<Net::Akismet>.

=head2 ip_addr

This is the IP address of the remote client of the author that made the comment.

=head2 http_referer

This is the HTTP referer that was sent by the browser when the author made the comment.

=head2 http_user_agent

This is the HTTP user agent that was sent by the browser when the author made the comment.

=cut

use Jifty::Record schema {
    column title =>
        type is 'text',
        label is 'Title',
        is mandatory,
        ;

    column body =>
        type is 'text',
        label is 'Body',
        is mandatory,
        render as 'Textarea',
        ;

    column created_on =>
        type is 'timestamp',
        label is 'Created on',
        filters are qw/ Jifty::DBI::Filter::DateTime /,
        ;

    column your_name =>
        type is 'text',
        label is 'Your name',
        is mandatory,
        ;

    column web_site =>
        type is 'text',
        label is 'Web site',
        ;

    column email =>
        type is 'text',
        label is 'Email address',
        ;

    column published =>
        type is 'boolean',
        label is 'Published?',
        is mandatory,
        default is 1,
        ;

    column status =>
        type is 'varchar(4)',
        label is 'Status',
        valid_values are qw/ spam ham /,
        default is 'ham',
        ;

    column ip_addr =>
        type is 'text',
        label is 'IP Address',
        ;

    column http_referer =>
        type is 'text',
        label is 'HTTP Referer',
        ;

    column http_user_agent =>
        type is 'text',
        label is 'HTTP User Agent',
        ;
};

use DateTime;
use HTML::Scrubber;

=head1 METHODS

=head2 table

Returns the database table name for the comments table.

=cut

sub table { 'comment_comments' }

=head2 before_create

It is assumed that your comments will be made available for create with very little restriction. This trigger is used to perform aggressive cleanup on the data stored and will attempt to check to see if the comment is spam by using L<Net::Akismet>.

=cut

sub before_create {
    my $self = shift;
    my $args = shift;

    # Clean up stuff added by Jifty::Plugin::Comment::Action::CreateComment
    delete $args->{parent_class};
    delete $args->{parent_id};

    my $plugin   = Jifty->find_plugin('Jifty::Plugin::Comment');
    my $scrubber = $plugin->scrubber;

    # Store safe fields
    $args->{'title'}           = Jifty->web->escape($args->{'title'});
    $args->{'your_name'}       = Jifty->web->escape($args->{'your_name'});
    $args->{'web_site'}        = Jifty->web->escape($args->{'web_site'});
    $args->{'email'}           = Jifty->web->escape($args->{'email'});
    $args->{'body'}            = $scrubber->scrub($args->{'body'});

    $args->{'created_on'}      = DateTime->now;

    $args->{'ip_addr'}         = $ENV{'REMOTE_ADDR'};
    $args->{'http_user_agent'} = $ENV{'HTTP_USER_AGENT'};
    $args->{'http_referer'}    = $ENV{'HTTP_REFERER'};

    # Prep for Akismet check or stop
    my $akismet = $plugin->akismet or return 1;

    # Check to see if it's classified as spam
    my $verdict = $akismet->check(
        USER_IP              => $args->{'ip_addr'},
        USER_AGENT           => $args->{'http_user_agent'},
        REFERER              => $args->{'http_referer'},
        COMMENT_CONTENT      => $args->{'title'}."\n\n".$args->{'body'},
        COMMENT_AUTHOR       => $args->{'your_name'},
        COMMENT_AUTHOR_EMAIL => $args->{'email'},
        COMMENT_AUTHOR_URL   => $args->{'web_site'},
    );

    # I have no idea what it is... mark it spam just in case...
    # TODO the default no verdict action should configurable
    if (!$verdict) {
        $args->{published} = 0;
        $args->{status}    = 'spam';

        warn "Failed to determine whether new comment is spam or not.";
        return 1;
    }

    # Naughty, naughty... mark as spam
    if ($verdict eq 'true') {
        warn "A new comment is detected as spam.";

        $args->{published} = 0;
        $args->{status}    = 'spam';

        return 1;
    }

    # Excellent, post that ham
    else {
        $args->{published} = 1;
        $args->{status}    = 'ham';

        return 1;
    }
}

=head2 before_set_status

This trigger is called when changing the status of the message. If L<Net::Akismet> is in use, this trigger will notify Akismet that this message is being marked as spam or as ham, depending upon the new value.

=cut

sub before_set_status {
    my $self = shift;
    my $args = shift;

    my $plugin  = Jifty->find_plugin('Jifty::Plugin::Comment');
    my $akismet = $plugin->akismet or return 1;

    my %akismet_report = (
        USER_IP              => $self->ip_addr,
        USER_AGENT           => $self->http_user_agent,
        REFERER              => $self->http_referer,
        COMMENT_CONTENT      => $self->title."\n\n".$self->body,
        COMMENT_AUTHOR       => $self->your_name,
        COMMENT_AUTHOR_EMAIL => $self->email,
        COMMENT_AUTHOR_URL   => $self->web_site,
    );

    if ($self->status eq 'spam' && $args->{value} eq 'ham') {
        if ($akismet->ham( %akismet_report )) {
            Jifty->log->info("Reported that comment ".$self->id." is HAM to Akismet.");
        }
        else {
            # Not the end of the world, just that Akismet doesn't know...
            Jifty->log->info("FAILED to report that comment ".$self->id." is HAM to Akismet.");
        }
    }

    elsif ($self->status eq 'ham' && $args->{value} eq 'spam') {
        if ($akismet->spam( %akismet_report )) {
            Jifty->log->info("Reported that comment ".$self->id." is SPAM to Akismet.");
        }
        else {
            # Not the end of the world, just that Akismet doesn't know...
            Jifty->log->info("FAILED to report that comment ".$self->id." is SPAM to Akismet.");
        }
    }

    return 1;
}

=head2 current_user_can

This method is not actually implemented by this class, but you will either want to implementt this method in your application or add a C<before_access> trigger that grants access. Otherwise, your comments won't be very interesting to anyone but a superuser.

See the L</SYNOPSIS> for a recommended implementation.

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;


