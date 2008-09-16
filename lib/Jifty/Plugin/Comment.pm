use strict;
use warnings;

package Jifty::Plugin::Comment;
use base qw/ Jifty::Plugin /;

__PACKAGE__->mk_accessors( qw/ akismet scrubber scrub_message / );

use HTML::Scrubber;

=head1 NAME

Jifty::Plugin::Comment - Add comments to any record

=head1 SYNOPSIS

Setup the F<config.yml>

  Plugins:
    - Comment:
      
      # Set this if you want spam checking by Net::Akismet
      Akismet:
        Key: 1234567890a
        Url: http://example.com

      # Set this if you want to customize the HTML scrubbing of comments
      Scrubber:
        message: "Comments may only contain <strong>, <em>, and <a> tags."
        allow:
          - strong
          - em
          - a
        default:
          - 0
          - 
            '*': 0
            href: !!perl/regexp:
              REGEXP: '^(?!(?:java)?script)'
              MODIFIERS: i

Setup a model that has comments:

  package App::Model::Fooble;
  
  use Jifty::DBI::Schema;
  use App::Record schema {
      column scribble => type is 'text';
      column wobble => type is 'int';
  };

  use Jifty::Plugin::Comment::Mixin::Model::Commented;

  sub allow_owner_update_delete {
      my $self = shift;
      my ($right, %args) = @_;

      if ($right eq 'create') {
          return 'allow' ;#if $self->current_user->id;
      }

      if ($right eq 'update' || $right eq 'delete') {
          return 'allow' if $self->current_user->id;
      }

      if ($right eq 'read') {
          return 'allow';
      }

      return 'deny';
  };

  App::Model::FoobleComment->add_trigger( name => 'before_access', callback => \&allow_owner_update_delete);
  App::Model::Comment->add_trigger( name => 'before_access', callback => \&allow_owner_update_delete);

Setup a view for creating, viewing, and managing the comments:

  # assuming $fooble here isa App::Action::UpdateFooble object
  template 'fooble/view' => page {
      my $fooble = get 'fooble';

      render_action $fooble, undef, { render_mode => 'read' };

      render_region
          name     => 'fooble-comments',
          path     => '__comment/list_and_add',
          defaults => { 
              comment_upon  => $fooble->record->for_commenting,
              initial_title => 'Re: '.substr($fooble->scribble, 0, 20).'...',
          },
          ;
  };

=head1 DESCRIPTION

This plugin allows you to attach comments to any model. You do this using the three steps listed in the synopsis. For variations on these steps, see the other classes that handle the individual parts.

=head1 COMMENTED RECORDS

To set up a commented model, you will need to do the following:

=over

=item 1 Add ths plugin to your project by modifying your F<config.yml>.

=item 1 Add the L<Jifty::Plugin::Comment::Mixin::Model::Commented> mixin to the model or models that you want to have comments attached to. See that class for details on how it works. You may also want to examine L<Jifty::Plugin::Comment::Model::Comment> on how to customize that class for your application.

=item 1 Create a view that appends a comment editor to your edit form (or on a separate page or wherever you feel like comments work best in your application). You should be able to use these views from either L<Template::Declare> or L<HTML::Mason> templates. See L<Jifty::Plugin::Comment::View> for additional details on what views are available.

=back

=head1 METHODS

=head2 init

Called during initialization. This will setup the L<Net::Akismet> object if it is configured and available.

=cut

sub init {
    my $self = shift;

    $self->_init_akismet(@_);
    $self->_init_scrubber(@_);
}

sub _init_akismet {
    my $self = shift;
    my %args = @_;

    # Stop now if we don't have the Akismet thing
    return unless defined $args{Akismet};

    # Check for the Akismet options
    my $key = $args{Akismet}{Key};
    my $url = $args{Akismet}{Url};

    # Don't go forward unless we have a key and a URL configured
    return unless $key and $url;

    # Try to load Akismet first...
    eval "use Net::Akismet";
    if ($@) {
        Jifty->log->error("Failed to load Net::Akismet. Your comments will not be checked for link spam and the like. $@");
        return;
    }

    # Now get our object
    my $akismet = Net::Akismet->new( KEY => $key, URL => $url );

    unless ($akismet) {
        Jifty->log->error("Failed to verify your Akismet key. Your comments will not be checked for link spam and the like.");
        return;
    }

    $self->akismet($akismet);
}

sub _init_scrubber {
    my $self = shift;
    my %args = @_;

    my $scrubber_args = $args{Scrubber};
    if (not defined $scrubber_args) {
        $scrubber_args = {
            message => 'Comments may only contain <strong>, <em>, and <a> tags.'
                      .' Anything else will be removed.',
            allow   => [ qw/ strong em a / ],
            default => [ 0, { '*' => 0, 'href' => qr{^(?!(?:java)?script)}i } ],
        };
    }

    my $scrub_message = delete $scrubber_args->{message};
    $scrub_message = 'The text you have given will be cleaned up.'
        unless $scrub_message;

    $self->scrub_message($scrub_message);

    my $scrubber = HTML::Scrubber->new( %$scrubber_args );

    $self->scrubber($scrubber);
}

=head2 akismet

This returns an instance of L<Net::Akismet> that is used to check to see if a new comment posted contains spam. No such checking is performed if this returns C<undef>, which indicates that C<Net::Akismet> is unavailable, wasn't configured, or there was an error configuring it (e.g., the Akismet server was unavailable during Jifty startup).

=head2 scrubber

This returns an instance of L<HTML::Scrubber> that is used to clean up HTML submitted in comments.

=head1 TO DO

Right now the module depends directly upon L<HTML::Scrubber> to do the work of cleaning up the text. You might want to use something else to do this. It also provides no mechanism for customizing any other aspect of the formatting. For example, your application might want to use Markdown, or BBCode, or just turn line breaks in the BR-tags, or anything else to format the comment text.

In the future, I'd like to consider something like L<Text::Pipe> or a similar API to allow these formats to be customized more easily.

=head1 SEE ALSO

L<Net::Akismet>, L<HTML::Scrubber>

=head1 AUTHOR

Andrew Sterling Hanenkamp, C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
