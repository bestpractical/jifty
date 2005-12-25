use warnings;
use strict;

package Jifty::Notification;

use base qw/Jifty::Object Class::Accessor/;
use Email::Send;
use Email::Simple;
use Email::Simple::Creator;

=head1 USAGE

It is recommended that you subclass L<Jifty::Notification> and override C<body>, C<subject>,
C<recipients>, and C<from> for each message.  (You may want a base class to provide C<from>, C<preface> and C<footer> for
example.)  This lets you keep all of your notifications in the same place.

However, if you really want to make a notification type in code without subclassing, you can
create a C<Jifty::Notification> and call the C<set_body>, C<set_subject>, and so on methods on
it.

=head1 METHODS

=cut

=head2 new [KEY1 => VAL1, ...]

Creates a new L<Jifty::Notification>.  Any keyword args given are used to call set accessors
of the same name.

Then it calls C<setup>.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my %args = @_;

    while (my ($arg, $value) = each %args) {
	if ($self->can($arg)) {
	    $self->$arg($value);
	} else {
	    $self->log->error((ref $self) . " called with invalid argument $arg");
	} 
    } 

    $self->setup;

    return $self;
} 

=head2 setup

Your subclass should override this to set the various field values.

=cut

sub setup {}

=head2 send

Delivers the notification, using the L<Email::Send> mailer defined in the C<Mailer>
and C<MailerArgs> configuration arguments.

=cut

sub send {
    my $self = shift;
    return unless $self->recipients;

    my $message = Email::Simple->create(
        header => [
            From => $self->from,
            To   => (join ', ', $self->recipients),
            Subject => $self->subject,
        ],
        body => join ("\n", $self->preface, $self->body, $self->footer)
    );

    my $method = Jifty->config->framework('Mailer');
    my $args_ref = Jifty->config->framework('MailerArgs');
    $args_ref = [] unless defined $args_ref;

    my $sender = Email::Send->new({mailer => $method, mailer_args => $args_ref });
    
    my $ret = $sender->send($message);

    unless ($ret) {
        $self->log->error("Error sending mail: $ret");
    } 

    $ret;
} 

=head2 body [BODY]

Gets or sets the body of the notification, as a string.

=head2 subject [SUBJECT]

Gets or sets the subject of the notification, as a string.  

=head2 from [FROM]

Gets or sets the from address of the notification, as a string.

=head2 recipients [RECIPIENT, ...]

Gets or sets the addresses of the recipients of the notification, as a list of strings
(not a reference).

=cut

__PACKAGE__->mk_accessors(qw/body preface footer subject from _recipients/);

sub recipients {
    my $self = shift;
    $self->_recipients([@_]) if @_;
    return @{ $self->_recipients || [] };
} 

1;
