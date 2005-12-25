package Jifty::SetupRequest;
use base qw/HTML::Mason::Plugin/;

sub start_request_hook {
    my ( $self, $context ) = @_;
    local $m = $context->request;
    unless ( $m->is_subrequest() ) {
        # can't get a base_comp in a plugin yet
        #    Jifty->web->handle_request();
    }
}
1;
