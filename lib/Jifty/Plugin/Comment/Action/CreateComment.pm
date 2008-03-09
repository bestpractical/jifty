use strict;
use warnings;

package Jifty::Plugin::Comment::Action::CreateComment;
use base qw/ Jifty::Action::Record::Create /;

use Jifty::Param::Schema;
use Jifty::Action::Record::Create schema {
    param parent_class =>
        type is 'hidden',
        is mandatory,
        order is 1,
        ;

    param parent_id =>
        type is 'hidden',
        is mandatory,
        order is 2,
        ;

    param title =>
        label is 'Title',
        is mandatory,
        ajax validates,
        is focus,
        order is 3,
        ;

    param your_name =>
        label is 'Your name',
        default is defer { from_cookie(0) },
        # TODO This is canonicalizing at the wrong time, I need another way.
#        ajax canonicalizes,
        order is 4,
        ;

    param web_site =>
        label is 'Web site',
        default is defer { from_cookie(1) },
        ajax validates,
        order is 5,
        ;

    param email =>
        label is 'Email address',
        default is defer { from_cookie(2) },
        ajax validates,
        order is 6,
        ;

#    param remember_me =>
#        type is 'checkbox',
#        label is 'Remember me',
#        hints is 'Check this box for this site to store a cookie on your browser that is used to automatically fill in your name, email address, and web site the next time you make a comment.',
#        ;

    param body =>
        type is 'textarea',
        label is 'Comment',
        is mandatory,
        ajax validates,
        order is 7,
        ;

    param published =>
        type is 'unrendered',
        render as 'unrendered',
        mandatory is 0,
        ;

    param created_on =>
        type is 'unrendered',
        render as 'unrendered',
        ;

    param status =>
        type is 'unrendered',
        render as 'unrendered',
        ;

    param http_referer =>
        type is 'unrendered',
        render as 'unrendered',
        ;

    param http_user_agent =>
        type is 'unrendered',
        render as 'unrendered',
        ;

    param ip_addr =>
        type is 'unrendered',
        render as 'unrendered',
        ;
};

use CGI::Cookie;
use MIME::Base64::URLSafe;
#use Contentment::Notification::CommentPublished;
#use Contentment::Notification::CommentNeedsModeration;
#use Contentment::Util;
use Regexp::Common qw/ Email::Address URI /;

sub record_class { Jifty->app_class('Model', 'Comment') }

sub parent {
    my $self = shift;

    my $parent_class = $self->argument_value('parent_class');
    my $parent_id    = $self->argument_value('parent_id');

    my $parent = $parent_class->new;
    $parent->load($parent_id);

    return $parent;
}

sub take_action {
    my $self = shift;

    if ($self->argument_value('submit')) {
        my $your_name     = urlsafe_b64encode($self->argument_value('your_name'));
        my $web_site      = urlsafe_b64encode($self->argument_value('web_site'));
        my $email = urlsafe_b64encode(
            $self->argument_value('email'));

        my $cookie = CGI::Cookie->new(
            -path    => '/',
            -name    => 'COMMENT_REMEMBORY',
            -value   => join('.', $your_name, $web_site, $email),
            -expires => '+3M',
        );

        Jifty->web->response->add_header( 'Set-Cookie' => $cookie->as_string );

        $self->SUPER::take_action(@_);

        # On success, create the extra link record
        if ($self->result->success) {
            my $parent_class = $self->argument_value('parent_class');
            my $link = $parent_class->comment_record_class->new;
            $link->create(
                commented_upon => $self->parent,
                the_comment    => $self->record,
            );

            # Link failed?
            unless ($link->id) {
                $self->log->error("Failed to create the comment and linking record required for comment #@{[$self->record->id]} and parent record class @{[$self->argument_value('parent_class')]} #@{[$self->argument_value('parent_id')]}");
                $self->result->message(undef);
                $self->result->error("Failed to create the comment and linking record required. This error has been logged.");
            }

            # Link succeeded! This comment's training is complete!
            else {
                # Send notification by email to the site owners
                my $notification_class 
                    = $self->record->published ? 'CommentPublished'
                    :                            'CommentNeedsModeration';
                $notification_class 
                    = Jifty->app_class('Notification', $notification_class);
                my $notification = $notification_class->new( 
                    comment => $self->record, 
                    parent  => $self->parent,
                );
                $notification->send;
            }
        }
    }
    else {
        $self->result->message(qq{Previewing your comment titled "@{[$self->argument_value('title') || 'Untitled']}"});
        $self->result->failure(1);
    }
}

sub report_success {
    my $self = shift;
    $self->result->message(_("Your comment has been added. If it does not immediately appear, it may have been flagged for moderation and should appear shortly."));
}

my $comment_cookie;
sub fetch_comment_cookie {
    return $comment_cookie if defined $comment_cookie;

    my %cookies = CGI::Cookie->fetch;
    $comment_cookie 
        = $cookies{'COMMENT_REMEMBORY'} ? $cookies{'COMMENT_REMEMBORY'} : '';

    return $comment_cookie;
}

sub from_cookie {
    my $pos = shift;

    if (Jifty->web->current_user->id) {
        return Jifty->web->escape(
               $pos == 0 ? Jifty->web->current_user->user_object->name
             : $pos == 1 ? Jifty->config->framework('Web')->{'BaseURL'}
             : $pos == 2 ? Jifty->web->current_user->user_object->email
             :             ''
        );
    }

    elsif (my $value = eval { fetch_comment_cookie()->value }) {
        my @fields = split /\./, $value;

        if (defined $fields[ $pos ]) {
            return Jifty->web->escape(urlsafe_b64decode($fields[ $pos ]));
        }
        else {
            return '';
        }
    }

    else {
        return '';
    }
}

sub validate_title {
    my $self = shift;
    my $title = shift;

    if (!$title || $title =~ /^\s*$/) {
        return $self->validation_error(title => 'You must give a title.');
    }

    return $self->validation_ok('title');
}

#sub canonicalize_your_name {
#    my $self = shift;
#    my $your_name = shift;
#
#    if (!$your_name || $your_name =~ /^\s*$/ || $your_name =~ /\banonymous\b/i) {
#        $self->canonicalization_note( your_name => 'Afraid to stand behind your words? Any malicious or evil comments by an Anonymous Coward (or anyone) will be unpublished.' );
#        return 'Anonymous Coward';
#    }
#
#    return $your_name;
#}

sub validate_web_site {
    my $self = shift;
    my $web_site = shift;

    if (!$web_site || $web_site =~ /^\s*$/) {
        return $self->validation_ok('web_site');
    }

    unless ($web_site =~ /^$RE{URI}{HTTP}$/) {
        return $self->validation_error(
            web_site => 'This does not look like a proper URL. Make sure it starts with http:// or https://'
        );
    }

    return $self->validation_ok('web_site');
}

sub validate_email {
    my $self = shift;
    my $email = shift;

    if (!$email || $email =~ /^\s*$/) {
        return $self->validation_ok('email');
    }

    unless ($email =~ /^$RE{Email}{Address}$/) {
        return $self->validation_error(
            email => 'This does not look like a proper e-mail address.',
        );
    }

    return $self->validation_ok('email');
}

sub validate_body {
    my $self = shift;
    my $body = shift;

    if (!$body || $body =~ /^\s*$/) {
        return $self->validation_error(body => 'You must type a comment.');
    }

    my $plugin = Jifty->find_plugin('Jifty::Plugin::Comment');
    my $scrubber = $plugin->scrubber;
    my $message  = $plugin->scrub_message;

    my $clean_body = $scrubber->scrub($body);
    if ($clean_body ne $body) {
        return $self->validation_warning(body => Jifty->web->escape($message));
    }

    return $self->validation_ok('body');
}

1;
