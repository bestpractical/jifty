use warnings;
use strict;

package Jifty::Script::Po;
use base qw(Jifty::Script Class::Accessor::Fast);

use Pod::Usage;
use File::Copy ();
use File::Path 'mkpath';
use Jifty::Config ();
use Jifty::YAML ();
use Locale::Maketext::Extract ();
use File::Find::Rule ();
use MIME::Types ();
our $MIME = MIME::Types->new();
our $LMExtract = Locale::Maketext::Extract->new(
        # Specify which parser plugins to use
        plugins => {
            # Use Perl parser, process files with extension .pl .pm .cgi
            'Locale::Maketext::Extract::Plugin::PPI' => ['pm','pl'],
            'tt2' => [ ],
            'perl' => ['pl','pm','js','json'],
            'mason' => [ ] ,
        },
        verbose => 1,
);

use constant USE_GETTEXT_STYLE => 1;

__PACKAGE__->mk_accessors(qw/language/);

### Help is below in __DATA__ section

=head2 options

Returns a hash of all the options this script takes. (See the usage message for details)

=cut

sub options {
    my $self = shift;
    return (
        $self->SUPER::options,
        'l|language=s' => 'language',
        'dir=s@'       => 'directories',
        'podir=s'      => 'podir',
        'js'           => 'js',
        'template_name=s' => 'template_name',
    )
}


=head2 run

Runs the "update_catalogs" method.

=cut


sub run {
    my $self = shift;
    return if $self->print_help;

    Jifty->new(no_handle => 1);

    return $self->_js_gen if $self->{js};

    $self->update_catalogs;
}

sub _js_gen {
    my $self = shift;
    my $static_handler = Jifty::View::Static::Handler->new;
    my $logger =Log::Log4perl->get_logger("main");
    for my $file ( @{ Jifty::Web->javascript_libs } ) {
        next if $file =~ m/^ext/;
        next if $file =~ m/^yui/;
        next if $file =~ m/^rico/;
        my $path = $static_handler->file_path( File::Spec->catdir( 'js', $file ) ) or next;

        $logger->info("Extracting messages from '$path'");

        $LMExtract->extract_file( $path );
    }

    $LMExtract->set_compiled_entries;
    $LMExtract->compile(USE_GETTEXT_STYLE);

    Jifty::I18N->new;
    mkpath ['share/web/static/js/dict'];
    for my $lang (Jifty::I18N->available_languages) {
        my $file = "share/web/static/js/dict/$lang.json";
        $logger->info("Generating $file");
        open my $fh, '>', $file or die "$file: $!";

        no strict 'refs';
        print $fh
            Jifty::JSON::encode_json( { map { my $text = ${"Jifty::I18N::".$lang."::Lexicon"}{$_};
                                              defined $text ? ( $_ => $text ) : () }
                                        keys %{$LMExtract->lexicon} } );
    }
}

=head2 _check_mime_type FILENAME

This routine returns a mimetype for the file C<FILENAME>.

=cut

sub _check_mime_type {
    my $self       = shift;
    my $local_path = shift;
    my $mimeobj = $MIME->mimeTypeOf($local_path);
    my $mime_type = ($mimeobj ? $mimeobj->type : "unknown");
    return if ( $mime_type =~ /^image/ );
    return 1;
}

=head2 update_catalogs

Extracts localizable messages from all files in your application, finds
all your message catalogs and updates them with new and changed messages.

=cut

sub update_catalogs {
    my $self = shift;
    my $podir = $self->{'podir'} || Jifty->config->framework('L10N')->{'PoDir'};

    $self->extract_messages;
    $self->update_catalog( File::Spec->catfile(
            $podir, $self->pot_name . ".pot"
        ) );

    if ($self->{'language'}) {
        $self->update_catalog( File::Spec->catfile(
            $podir, $self->{'language'} . ".po"
        ) );
        return;
    }

    my @catalogs = grep !m{(^|/)\.svn/}, File::Find::Rule->file->name('*.po')->in(
        $podir
    );

    unless ( @catalogs ) {
        $self->log->error("You have no existing message catalogs.");
        $self->log->error("Run `jifty po --language <lang>` to create a new one.");
        $self->log->error("Read `jifty po --help` to get more info.");
        return 
    }

    foreach my $catalog (@catalogs) {
        $self->update_catalog( $catalog );
    }
}

=head2 update_catalog FILENAME

Reads C<FILENAME>, a message catalog and integrates new or changed 
translations.

=cut

sub update_catalog {
    my $self       = shift;
    my $translation = shift;
    my $logger =Log::Log4perl->get_logger("main");
    $logger->info( "Updating message catalog '$translation'");

    $LMExtract->read_po($translation) if ( -f $translation && $translation !~ m/pot$/ );

    my $orig_lexicon;

    # Reset previously compiled entries before a new compilation
    $LMExtract->set_compiled_entries;
    $LMExtract->compile(USE_GETTEXT_STYLE);

    if ($self->_is_core && !$self->{'template_name'}) {
        $LMExtract->write_po($translation);
    }
    else {
        $orig_lexicon = $LMExtract->lexicon;
        my $lexicon = { %$orig_lexicon };

        # XXX: cache core_lm
        my $core_lm = Locale::Maketext::Extract->new();
        Locale::Maketext::Lexicon::set_option('allow_empty' => 1);
        $core_lm->read_po( File::Spec->catfile(
            Jifty->config->framework('L10N')->{'DefaultPoDir'}, 'jifty.pot'
        ));
        Locale::Maketext::Lexicon::set_option('allow_empty' => 0);
        for (keys %{ $core_lm->lexicon }) {
            next unless exists $lexicon->{$_};
            # keep the local entry overriding core if it exists
            delete $lexicon->{$_} unless length $lexicon->{$_};
        }
        $LMExtract->set_lexicon($lexicon);

        $LMExtract->write_po($translation);

        $LMExtract->set_lexicon($orig_lexicon);
    }
}


=head2 extract_messages

Find all translatable messages in your application, using 
L<Locale::Maketext::Extract>.

=cut

sub extract_messages {
    my $self = shift;
    # find all the .pm files in @INC
    my @files = File::Find::Rule->file->in( @{ $self->{directories} ||
                                                   [ Jifty->config->framework('Web')->{'TemplateRoot'},
                                                     'lib', 'bin'] } );

    my $logger =Log::Log4perl->get_logger("main");
    foreach my $file (@files) {
        next if $file =~ m{(^|/)[\._]svn/};
        next if $file =~ m{\~$};
        next if $file =~ m{\.pod$};
        next unless $self->_check_mime_type($file );
        $logger->info("Extracting messages from '$file'");
        $LMExtract->extract_file($file);
    }

}

=head2 print_help

Prints out help for the package using pod2usage.

If the user specified --help, prints a brief usage message

If the user specified --man, prints out a manpage

=cut

sub print_help {
    my $self = shift;
    return 0 unless $self->{help} || $self->{man};

    # Option handling
    my $docs = \*DATA;
    pod2usage( -exitval => 1, -input => $docs ) if $self->{help};
    pod2usage( -exitval => 0, -verbose => 2, -input => $docs )
        if $self->{man};
    return 1;
}


sub _is_core {
    return 1 if Jifty->config->framework('ApplicationName') eq 'JiftyApp';
}

=head2 pot_name

Returns the name of the po template.

=cut

sub pot_name {
    my $self = shift;
    return $self->{'template_name'} if $self->{'template_name'};
    return 'jifty' if $self->_is_core;
    return lc  Jifty->config->framework('ApplicationName');
}

1;

__DATA__

=head1 NAME

Jifty::Script::Po - Extract translatable strings from your application

=head1 SYNOPSIS

  jifty po --language <lang>  Creates a <lang>.po file for translation
  jifty po                    Updates all existing po files

 Options:
   --language         Language to deal with
   --dir              Additionl dirs to extract from
   --js               Generate json files from the current po files

   --help             brief help message
   --man              full documentation

=head1 OPTIONS

=over 8

=item B<--language>

This script an option, C<--language>, which is optional; it is the
name of a message catalog to create.

=item B<--dir>

Specify explicit directories to extract from. Can be used multiple
times.  The default directores will not be extracted if you use this option.

=item B<--template_name>

Specify the name of the po template.  Default to the lower-cased application name.

=item B<--podir>

Specify the directory of the po templates.

=item B<--js>

If C<--js> is given, other options are ignored and the script will
generate json files for each language under
F<share/web/static/js/dict> from the current po files.  Before doing
so, you might want to run C<jifty po> with C<--dir share/web/static/js>
to include messages from javascript in your po files.

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

Extracts message catalogs for your Jifty app. When run, Jifty will update
all existing message catalogs, as well as create a new one if you specify
a --language option.

=cut

