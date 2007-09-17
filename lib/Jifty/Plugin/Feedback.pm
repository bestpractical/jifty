use strict;
use warnings;

package Jifty::Plugin::Feedback;
use base qw/Jifty::Plugin Class::Accessor::Fast/;

# Your plugin goes here.  If takes any configuration or arguments, you
# probably want to override L<Jifty::Plugin/init>.

=head1 NAME

Jifty::Plugin::Feedback

=head1 DESCRIPTION

This plugin provides a "feedback box" for your app.


Add to your app's config:

  Plugins: 
    - Feedback: 
        from: defaultsender@example.com
        to: recipient@example.com

Add to your app's UI where you want the feedback box:

 show '/feedback/request_feedback';


=cut

__PACKAGE__->mk_accessors(qw(from to));

=head2 init

Initializes the Feedback object. Takes a paramhash with keys 'from' and 'to', which are email addresses.

=cut

sub init {
    my $self = shift;
    my %opt = @_;
    $self->from($opt{'from'});
    $self->to($opt{'to'});
}

1;
