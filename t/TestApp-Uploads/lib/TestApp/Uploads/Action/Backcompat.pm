package TestApp::Uploads::Action::Backcompat;
use strict;
use warnings;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param 'upload_file' =>
        label is 'Upload file',
        render as 'Upload';
};

sub take_action {
    my $self = shift;
    my $filehandle = $self->argument_value('upload_file');

    my $first_line = <$filehandle>;
    chomp $first_line;

    $self->result->content(first_line => $first_line);

    return 1;
}

1;

