use strict;
use warnings;

package JFDI::Handler;

=head1 NAME

JFDI::Handler - Methods related to the Mason handler

=head1 SYNOPSIS

  use JFDI::Handler

  my $cgihandler = HTML::Mason::CGIHandler->new( JFDI::Handler->mason_config );

  # after each request is handled
  JFDI::Handler->cleanup_request;

=head1 DESCRIPTION

L<JFDI::Handler> provides methods required to deal with Mason CGI handlers.
Note that at this time there are no objects with L<JFDI::Handler> as a class.

=head2 mason_config

Returns our Mason config.  We have a global called C<$framework>, use C<JFDI::MasonInterp>
as our Mason interpreter, and have a component root as specified in the C<Web/TemplateRoot> framework
configuration variable (or C<html> by default).  All interpolations are HTML-escaped by default, and
we use the fatal error mode.

=cut

sub mason_config {
    return (
        allow_globals => [qw[$framework]],
        interp_class  => 'JFDI::MasonInterp',
        comp_root     => JFDI->absolute_path(
            JFDI->framework_config('Web')->{'TemplateRoot'} || "html"
        ),
        error_mode => 'fatal',
        error_format => 'text',
        default_escape_flags => 'h',
    );
}


=head2 cleanup_request

Dispatchers should call this at the end of each request, as a class method.

Currently, tries to flush L<Jifty::DBI>'s cache. 

=cut

sub cleanup_request {
    # Clean out the cache. the performance impact should be marginal.
    # Consistency is imprived, too.
    JFDI::Record->flush_cache if UNIVERSAL::can('JFDI::Record', 'flush_cache');
}

1;
