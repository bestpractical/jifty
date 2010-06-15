package TestApp::Notification::Foo;
use warnings;
use strict;
use base qw(TestApp::Notification);
use utf8;

sub setup {
    my $self = shift;
    $self->SUPER::setup(@_);

    $self->recipients('foo@email');
    $self->subject('subject');
    $self->from('from');
}

sub body {
    return Jifty->web->url( path => '/notification/foo' ) . "\n\n";
}

1;
