use strict;
use warnings;

package Jifty::View::Mason::Request;
# Subclass for HTML::Mason::Request object $m

=head1 NAME

Jifty::View::Mason::Request -View mason request

=head1 DESCRIPTION

Subclass of L<HTML::Mason::Request> which is customised for Jifty's use.

=cut

use HTML::Mason::Exceptions;
use HTML::Mason::Request;
use base qw/HTML::Mason::Request/;

=head2 auto_send_headers

Doesn't send headers if this is a subrequest (according to the current
L<Jifty::Request>).

=cut

sub auto_send_headers {
    Jifty::View->auto_send_headers;
}

=head2 exec

Actually runs the component; in case no headers have been sent after
running the component, and we're supposed to send headers, sends them.

=cut

sub exec
{
    my $self = shift;
    my $retval;

    eval { $retval = $self->SUPER::exec(@_) };

    if (my $err = $@)
    {
        $retval = isa_mason_exception($err, 'Abort')   ? $err->aborted_value  :
                  isa_mason_exception($err, 'Decline') ? $err->declined_value :
                  rethrow_exception $err;
    }

    return $retval;
}

=head2 print

=head2 out

Append to the shared L<String::BufferStack> stored in L<Jifty::Handler/buffer>.

=cut

sub print {
    shift;
    Jifty->handler->buffer->append(@_);
}

*out = \&print;

=head2 comp

Jump through hoops necessary to keep L<Jifty::Handler/buffer> lined up
with Mason's internal buffer stack.

=cut

sub comp {
    my $self = shift;

    my %mods;
    %mods = (%{shift()}, %mods) while ref($_[0]) eq 'HASH';
    my @args;
    push @args, buffer => delete $mods{store} if $mods{store} and $mods{store} ne \($self->{request_buffer});
    my $file = (ref $_[0] ? $_[0]{path} : $_[0]);
    Jifty->handler->buffer->push(@args, from => "Mason path $file", file => $file);

    my $wantarray = wantarray;
    my @result;
    if ($wantarray) {
        @result = $self->SUPER::comp(\%mods, @_);
    } elsif (defined $wantarray) {
        $result[0] = $self->SUPER::comp(\%mods, @_);
    } else {
        $self->SUPER::comp(\%mods, @_);
    }
    Jifty->handler->buffer->pop;
    return $wantarray ? @result : $result[0];    
}

=head2 content

Jump through hoops necessary to keep L<Jifty::Handler/buffer> lined up
with Mason's internal buffer stack.

=cut

sub content {
    my $self = shift;

    Jifty->handler->buffer->push( private => 1, from => "Mason call to content" );
    $self->SUPER::content;
    return Jifty->handler->buffer->pop;
}

=head2 redirect

Calls L<Jifty::Web/redirect>.

=cut

sub redirect {
    my $self = shift;
    my $url = shift;

    Jifty->web->redirect($url);
}

1;
