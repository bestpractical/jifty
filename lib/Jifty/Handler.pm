use strict;
use warnings;

package Jifty::Handler;

=head1 NAME

Jifty::Handler - Methods related to the Mason handler

=head1 SYNOPSIS

  use Jifty::Handler

  my $cgihandler = HTML::Mason::CGIHandler->new( Jifty::Handler->mason_config );

  # after each request is handled
  Jifty::Handler->cleanup_request;

=head1 DESCRIPTION

L<Jifty::Handler> provides methods required to deal with Mason CGI handlers.
Note that at this time there are no objects with L<Jifty::Handler> as a class.

=head2 mason_config

Returns our Mason config.  We have a global called C<$framework>, use C<Jifty::MasonInterp>
as our Mason interpreter, and have a component root as specified in the C<Web/TemplateRoot> framework
configuration variable (or C<html> by default).  All interpolations are HTML-escaped by default, and
we use the fatal error mode.

=cut

sub mason_config {
    return (
        allow_globals => [qw[$framework]],
        interp_class  => 'Jifty::MasonInterp',
        comp_root     => Jifty->absolute_path(
            Jifty->framework_config('Web')->{'TemplateRoot'} || "html"
        ),
        error_mode => 'fatal',
        error_format => 'text',
        default_escape_flags => 'h',
        #       plugins => ['Jifty::SetupRequest']
    );
}


=head2 cleanup_request

Dispatchers should call this at the end of each request, as a class method.

Currently, tries to flush L<Jifty::DBI>'s cache. 

=cut

sub cleanup_request {
    # Clean out the cache. the performance impact should be marginal.
    # Consistency is improved, too.
    Jifty::Record->flush_cache;
}

1;
