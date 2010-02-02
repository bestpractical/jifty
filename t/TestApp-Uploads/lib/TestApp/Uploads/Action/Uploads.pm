package TestApp::Uploads::Action::Uploads;
use strict;
use warnings;
use base 'Jifty::Action';
use UNIVERSAL::isa;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param content =>
        label is 'File',
        render as 'Uploads';
};

sub take_action {
    my $self = shift;

    my $attachments = $self->argument_value('content');
    $self->result->content(files => {});
    for my $att ( ref $attachments eq 'ARRAY' ? @$attachments : $attachments ) {
        next unless $att && $att->isa('Jifty::Web::FileUpload');
        $self->result->content('files')->{$att->filename} = $att->content;
    }
    return 1;
}

1;

