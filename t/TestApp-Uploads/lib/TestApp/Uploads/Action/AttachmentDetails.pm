package TestApp::Uploads::Action::AttachmentDetails;
use strict;
use warnings;
use base 'Jifty::Action';

use Jifty::Param::Schema;
use Jifty::Action schema {
    param content =>
        label is 'File',
        render as 'Upload';
};

sub take_action {
    my $self = shift;

    my $attachment = $self->argument_value('content');

    $self->result->content(filename => $attachment->filename);
    $self->result->content(content_type => $attachment->content_type);
    $self->result->content(length => length($attachment->content));
    $self->result->content(stringify => "$attachment");
    $self->result->content(scalar_ref => $$attachment);

    return 1;
}

1;

