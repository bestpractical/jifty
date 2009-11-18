package Jifty::Web::FileUpload;
use strict;
use warnings;
use base qw/Jifty::Object Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw(filehandle content filename content_type));

=head1 NAME

Jifty::Web::FileUpload - Describes an HTTP file upload

=head1 DESCRIPTION

Currently this module is very much geared towards the use case of the current
request offering a file upload, and inspecting L<CGI> to produce metadata.

Refactorings to eliminate these assumptions are very welcome.

=head2 new PARAMHASH

Creates a new file upload object.  The possible arguments in the C<PARAMHASH>
are:

=over

=item filehandle

The filehandle to read the content from. This must be a L<Fh> object produced
by CGI.

=item content (optional)

The upload's content. Will be intuited if possible.

=item filename (optional)

The upload's filename as given by the client (i.e. E<not> on disk).
Will be intuited if possible.

=item content_type (optional)

The content type as reported by the client.

=back

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my %args = (
        filehandle   => undef,
        content      => undef,
        filename     => undef,
        content_type => undef,
        @_,
    );

    my $fh = $args{filehandle};

    ref($fh) eq 'Fh'
        or die "The filehandle must be an Fh object produced by CGI";

    if (!defined($args{content})) {
        binmode $fh;
        local $/;
        $args{content} = <$fh>;
    }

    if (!defined($args{filename})) {
        $args{filename} = "$fh";
    }

    if (!defined($args{content_type})) {
        my $info = Jifty->handler->cgi->uploadInfo($fh);
        $args{content_type} = $info->{'Content-Type'}
            if defined $info;
    }

    $self->filehandle($fh);
    $self->content($args{content});
    $self->filename($args{filename});
    $self->content_type($args{content_type});

    return $self;
}

1;

