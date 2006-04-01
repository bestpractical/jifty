use warnings;
use strict;

package Jifty::Script::Po;
use base qw'App::CLI::Command Class::Accessor';

use File::Copy;
use Jifty::Config;
use Jifty::YAML;
use Locale::Maketext::Extract;
use File::Find::Rule;
use MIME::Types;
our $mime  = MIME::Types->new();
our $LMExtract = Locale::Maketext::Extract->new;

__PACKAGE__->mk_accessors(qw/language/);


=head1 NAME

Jifty::Script::Po - Extract translatable strings from your application

=head1 DESCRIPTION

Extracts message catalogs for your Jifty app. When run, Jifty will update
all existing message catalogs, as well as create a new one if you specify a --language flag

=head2 options

This script only takes one option, C<--language>, which is optional; it is
the name of a message catalog to create.  

=cut

sub options {
    (
     'l|language=s' => 'language',
    )
}


=head2 run

Runs the "update_catalogs" method.

=cut


sub run {
        my $self = shift;
            Jifty->new(no_handle => 1);
        $self->update_catalogs;
}

=head2 _check_mime_type FILENAME

=cut

sub _check_mime_type {
    my $self       = shift;
    my $local_path = shift;
    my $mimeobj = $mime->mimeTypeOf($local_path);
    my $mime_type = ($mimeobj ? $mimeobj->type : "unknown");
    return if ( $mime_type =~ /^image/ );
    return 1;
}

sub update_catalogs {
    my $self = shift;
    $self->extract_messages();
    my @catalogs = File::Find::Rule->file->in(
        Jifty->config->framework('L10N')->{'PoDir'} );
    foreach my $catalog (@catalogs) {
        $self->update_catalog( $catalog );
    }
    if ($self->{'language'}) { 
        $self->update_catalog( File::Spec->catfile( Jifty->config->framework('L10N')->{'PoDir'}, $self->{'language'} . ".po"));
    }

}


sub update_catalog {
    my $self       = shift;
    my $translation = shift;
    my $logger =Log::Log4perl->get_logger("main");
    $logger->info( "Updating message catalog '$translation'");
    $LMExtract->read_po($translation) if ( -f $translation );
    $LMExtract->compile;
    $LMExtract->write_po($translation);
}



sub extract_messages {
    my $self = shift;
    # find all the .pm files in @INC
    my @files = File::Find::Rule->file->in( 'share', 'lib', 'bin' );

    my $logger =Log::Log4perl->get_logger("main");
    foreach my $file (@files) {
        next unless $self->_check_mime_type($file );
        $logger->info("Extracting messages from '$file'");
        $LMExtract->extract_file($file);
    }

}

1;
