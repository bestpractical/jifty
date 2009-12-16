package TestApp::Notification::Foo;
use warnings;
use strict;
use base qw(TestApp::Notification);
use utf8;

sub setup {
    my $self = shift;
    $self->SUPER::setup(@_);
    warn 'Foo here';

    $self->recipients('foo@email');
    $self->subject('subject');
    $self->from('from');
    $self->body('body');
}


1;
