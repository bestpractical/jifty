package Jifty::View::Declare::Handler;

use warnings;
use strict;

use base qw/Jifty::Object Class::Accessor/;
use Template::Declare;


__PACKAGE__->mk_accessors(qw/root_class/);

=head2 show $package $template

=cut


sub new {
    my $class = shift;
    my $self = {};
    bless $self,$class;
    Template::Declare->init(@_);
    return $self;
}


sub show {
    my $self = shift;
    my $code_template = shift;

    no warnings qw/redefine utf8/;
    local *Jifty::Web::out = sub {
        shift;  # Remove the $self in Jifty::Web->out
        goto &Template::Declare::Tags::outs;
    };

    local $Template::Declare::Tags::BUFFER = '';

    my $rv = Template::Declare::Tags::show($code_template);

    # XXX - Kluge - Before $r->send_http_headers is fixed for real, escape all non-latin1 characters.
    print STDOUT Encode::encode(latin1 => $rv, &Encode::FB_XMLCREF)
        unless Jifty->handler->apache->http_header_sent;

    return undef;
}

sub resolve_template { my $pkg =shift;  return Template::Declare->resolve_template(@_);}

1;
