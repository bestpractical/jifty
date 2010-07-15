package Jifty::Web::FileUpload;
use strict;
use warnings;
use base qw/Jifty::Object Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw(filehandle _content filename content_type));

use overload (
    q{""} => sub { $_[0]->filename },
    '*{}' => sub { $_[0]->filehandle },
    '${}' => sub { \($_[0]->filename) },
    fallback => 1,
);

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

The filehandle to read the content from. If this is not an L<Fh> object
produced by L<CGI>, then C<content_type> is mandatory and you probably want to
set C<filename> yourself.

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

    if (!defined($args{filename})) {
        $args{filename} = "$fh";

        # Strip all but the basename for consistency between browsers
        $args{filename} =~ s#^.*[\\/]##;
    }

    if (!defined($args{content_type})) {
        ref($fh) eq 'Fh'
            or die "The filehandle must be an Fh object produced by CGI";

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

=head2 content

Lazily slurps in the filehandle's content.

=cut

sub content {
    my $self = shift;
    if (@_) {
        return $self->_content(@_);
    }

    my $content = $self->_content;
    if (!defined($content)) {
        my $fh = $self->filehandle;;
        local $/;
        $content = <$fh>;
        $self->_content($content);
    }

    return $content;
}

=head2 new_from_fh Fh

Convenience method, since the other bits can be gleaned from the L<Fh> object.

=cut

# DEPRECATED
sub new_from_fh {
    my $self = shift;
    my $fh   = shift;

    $self->new(filehandle => $fh);
}

=head2 new_from_plack $u

=cut

sub new_from_plack {
    my $self = shift;
    my $u    = shift;

    open my $fh, '<:raw', $u->tempname
        or die "Can't open '@{[ $u->tempname ]}': '$!'";

    $self->new(filehandle   => $fh,
               filename     => $u->basename,
               content_type => $u->type,
           );
}

1;

