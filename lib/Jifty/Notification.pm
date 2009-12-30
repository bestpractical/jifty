use warnings;
use strict;

package Jifty::Notification;

use base qw/Jifty::Object Class::Accessor::Fast/;
use Email::Send            ();
use Email::MIME::Creator;
use Email::MIME::CreateHTML;
use Email::MIME::Modifier;

__PACKAGE__->mk_accessors(
    qw/body html_body preface footer subject from _recipients _to_list to/);

=head1 NAME

Jifty::Notification - Send emails from Jifty

=head1 USAGE

It is recommended that you subclass L<Jifty::Notification> and
override C<body>, C<html_body>, C<subject>, C<recipients>, and C<from>
for each message.  (You may want a base class to provide C<from>,
C<preface> and C<footer> for example.)  This lets you keep all of your
notifications in the same place.

However, if you really want to make a notification type in code
without subclassing, you can create a C<Jifty::Notification> and call
the C<set_body>, C<set_subject>, and so on methods on it.

=head1 METHODS

=cut

=head2 new [KEY1 => VAL1, ...]

Creates a new L<Jifty::Notification>.  Any keyword args given are used
to call set accessors of the same name.

Then it calls C<setup>.

=cut

sub new {
    my $class = shift;
    my $self  = bless {}, $class;

    my %args = @_;

    # initialize message bits to avoid 'undef' warnings
    #for (qw(body preface footer subject)) { $self->$_(''); }
    $self->_recipients( [] );

    while ( my ( $arg, $value ) = each %args ) {
        if ( $self->can($arg) ) {
            $self->$arg($value);
        } else {
            $self->log->error(
                ( ref $self ) . " called with invalid argument $arg" );
        }
    }

    $self->setup;

    return $self;
}

=head2 setup

Your subclass should override this to set the various field values.

=cut

sub setup { }

=head2 send_one_message

Delivers the notification, using the L<Email::Send> mailer defined in
the C<Mailer> and C<MailerArgs> configuration arguments.  Returns true
if mail was actually sent.  Note errors are not the only cause of mail
not being sent -- for example, the recipients list could be empty.

If you wish to send HTML mail, set C<html_body>.  If this is not set
(for backwards compatibility) a plain-text email is sent.  If
C<html_body> and C<body> are both set, a multipart mail is sent.  See
L<Email::MIME::CreateHTML> for how this is done.

Be aware that if you haven't set C<recipients>, this will fail
silently and return without doing anything useful.

=cut

sub send_one_message {
    my $self       = shift;
    my @recipients = $self->recipients;
    my $to         = join( ', ',
        map { ( ref $_ && $_->can('email') ? $_->email : $_ ) } grep {$_} @recipients );
    $self->log->debug("Sending a ".ref($self)." to $to"); 
    return unless ($to);
    my $message = "";
    my $appname = Jifty->config->framework('ApplicationName');

    my %attrs = ( charset => 'UTF-8' );

    my $from = Encode::encode(
        'MIME-Header',
        $self->from || _('%1 <%2>' , $appname, Jifty->config->framework('AdminEmail'))
    );
    my $subj = Encode::encode(
        'MIME-Header',
        $self->subject || _("A notification from %1!",$appname )
    );

    if ( defined $self->html_body ) {

        # Email::MIME takes _bytes_, not characters, for the "body"
        # argument, so we need to encode the full_body into UTF8.
        # Modern Email::MIME->create takes a "body_str" argument which
        # does the encoding for us, but Email::MIME::CreateHTML
        # doesn't grok it.  See also L</parts> for the other location
        # which does the encode.
        $message = Email::MIME->create_html(
            header => [
                From    => $from,
                To      => $to,
                Subject => $subj,
            ],
            attributes           => \%attrs,
            text_body_attributes => \%attrs,
            body_attributes      => \%attrs,
            text_body            => Encode::encode_utf8( $self->full_body ),
            body                 => Encode::encode_utf8( $self->full_html ),
            embed                => 0,
            inline_css           => 0,
        );

        # Since the containing messsage will still be us-ascii otherwise
        $message->charset_set( $attrs{'charset'} );
    } else {
        $message = Email::MIME->create(
            header => [
                From    => $from,
                To      => $to,
                Subject => $subj,
            ],
            attributes => \%attrs,
            parts      => $self->parts,
        );
    }
    $message->encoding_set('8bit')
        if ( scalar $message->parts == 1 );
    $self->set_headers($message);

    my $method   = Jifty->config->framework('Mailer');
    my $args_ref = Jifty->config->framework('MailerArgs');
    $args_ref = [] unless defined $args_ref;

    my $sender
        = Email::Send->new( { mailer => $method, mailer_args => $args_ref } );

    my $ret = $sender->send($message);

    unless ($ret) {
        $self->log->error("Error sending mail: $ret");
    }

    $ret;
}

=head2 set_headers MESSAGE

Takes a L<Email::MIME> object C<MESSAGE>, and modifies it as
necessary before sending it out.  As the method name implies, this is
usually used to add or modify headers.  By default, does nothing; this
method is meant to be overridden.

=cut

sub set_headers {}

=head2 body [BODY]

Gets or sets the body of the notification, as a string.

=head2 subject [SUBJECT]

Gets or sets the subject of the notification, as a string.

=head2 from [FROM]

Gets or sets the from address of the notification, as a string.

=head2 recipients [RECIPIENT, ...]

Gets or sets the addresses of the recipients of the notification, as a
list of strings (not a reference).

=cut

sub recipients {
    my $self = shift;
    $self->_recipients( [@_] ) if @_;
    return @{ $self->_recipients };
}

=head2 email_from OBJECT

Returns the email address from the given object.  This defaults to
calling an 'email' method on the object.  This method will be called
by L</send> to get email addresses (for L</to>) out of the list of
L</recipients>.

=cut

sub email_from {
    my $self = shift;
    my ($obj) = @_;
    if ( $obj->can('email') ) {
        return $obj->email;
    } else {
        die "No 'email' method on " . ref($obj) . "; override 'email_from'";
    }
}

=head2 to_list [OBJECT, OBJECT...]

Gets or sets the list of objects that the message will be sent to.
Each one is sent a separate copy of the email.  If passed no
parameters, returns the objects that have been set.  This also
suppresses duplicates.

=cut

sub to_list {
    my $self = shift;
    if (@_) {
        my %ids = ();
        $ids{ $self->to->id } = undef if $self->to;
        $ids{ $_->id } = $_ for @_;
        $self->_to_list( [ grep defined, values %ids ] );
    }
    return @{ $self->_to_list || [] };
}

=head2 send

Sends an individual email to every user in L</to_list>; it does this by
setting L</to> and L</recipient> to the first user in L</to_list>
calling L<Jifty::Notification>'s C<send> method, and progressing down
the list.

Additionally, if L</to> was set elsewhere, sends an email to that
person, as well.

=cut

sub send {
    my $self = shift;
    my $currentuser_object_class = Jifty->app_class("CurrentUser");
    for my $to ( grep {defined} ($self->to, $self->to_list) ) {
        if ($to->can('id')) {
        next if     $currentuser_object_class->can("nobody")
                and $currentuser_object_class->nobody->id
                and $to->id == $currentuser_object_class->nobody->id;
                
        next if $to->id == $currentuser_object_class->superuser->id;
        } 
        $self->to($to);
        $self->recipients($to);
        $self->send_one_message(@_);
    }
}

=head2 to

Of the list of users that C<to> provided, returns the one which mail
is currently being sent to.  This is set by the L</send> method, such
that it is available to all of the methods that
L<Jifty::Notification>'s C<send> method calls.

=cut

=head2 preface

Print a header for the message. You want to override this to print a message.

Returns the message as a scalar.

=cut

=head2 footer

Print a footer for the message. You want to override this to print a message.

Returns the message as a scalar.

=cut

=head2 full_body

The main, plain-text part of the message.  This is the preface,
body, and footer joined by newlines.

=cut

sub full_body {
  my $self = shift;
  return join( "\n", grep { defined } $self->preface, $self->body, $self->footer );
}

=head2 full_html

Same as full_body, but with HTML.

=cut

sub full_html {
  my $self = shift;
  return join( "\n", grep { defined } $self->preface, $self->html_body, $self->footer );
}

=head2 parts

The parts of the message.  You want to override this if you want to
send multi-part mail.  By default, this method returns a single
part consisting of the result of calling C<< $self->full_body >>.

Returns the parts as an array reference.

=cut

sub parts {
  my $self = shift;
# NOTICE: we should keep string in perl string (with utf8 flag)
# rather then encode it into octets. Email::MIME would call Encode::encode in 
# its create function.
  return [ Email::MIME->create(
      attributes => { charset => 'UTF-8' },
      body       => Encode::encode_utf8( $self->full_body ),
    ) ];
}

=head2 magic_letme_token_for PATH

Returns a L<Jifty::LetMe> token which allows the current user to access a path on the
site. 

=cut

sub magic_letme_token_for {
    my $self = shift;
    my $path = shift;
    my %args = @_;

    my $letme = Jifty::LetMe->new();
    $letme->email( $self->to->email );
    $letme->path($path);
    $letme->args( \%args );
    return ( $letme->as_url );
}

1;
