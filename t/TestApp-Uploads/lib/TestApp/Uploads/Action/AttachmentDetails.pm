package TestApp::Uploads::Action::AttachmentDetails;
use strict;
use warnings;
use base 'Jifty::Action';

use Jifty::Param::Schema;
use Jifty::Action schema {
    param content =>
        label is 'File',
        render as 'Uploads';
};

sub take_action {
    my $self = shift;

    my $attachments = $self->argument_value('content');

    my @att = ref $attachments eq 'ARRAY' ? @$attachments : $attachments;
    my @contents;
    for my $att (@att) {
        push @contents,
          {
            filename     => $att->filename,
            content_type => $att->content_type,
            length       => length $att->content,
            stringify    => "$att",
            scalar_ref    => $$att,
          };
    }
    $self->result->content(contents => \@contents);
    return 1;
}

1;

