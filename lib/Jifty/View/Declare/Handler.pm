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
    my $self          = shift;
    my $code_template = shift;

    no warnings qw/redefine utf8/;
    local *Jifty::Web::out = sub {
        shift;    # Turn the method into a function
        unless ( Jifty->handler->stash->{http_header_sent} ) {
            $self->send_http_header();
        }

        local $Template::Declare::Tags::BUFFER = '';
        goto &Template::Declare::Tags::outs;
    };
    print STDOUT Template::Declare::Tags::show($code_template);

    return undef;
}

sub send_http_header {
    my $self = shift;
    my $r = Jifty->handler->apache;
    $r->content_type
        || $r->content_type('text/html; charset=utf-8');    # Set up a default
    if ( $r->content_type =~ /charset=([\w-]+)$/ ) {
        my $enc = $1;
        binmode *STDOUT,
            ( ( lc($enc) =~ /utf-?8/ ) ? ":utf8" : "encoding($enc)" );
    }

    #HTML::Mason::FakeApache's send_http_header uses "print STDOUT"
    # this reimplements that.
    print STDOUT $r->http_header;
    Jifty->handler->stash->{http_header_sent} = 1;
}

sub resolve_template { my $pkg =shift;  return Template::Declare->resolve_template(@_);}

1;
