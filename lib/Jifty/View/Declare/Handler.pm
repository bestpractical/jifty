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
        unless ( Jifty->handler->apache->http_header_sent ) {
            Jifty->handler->apache->send_http_header();
        }

        local $Template::Declare::Tags::BUFFER = '';
        goto &Template::Declare::Tags::outs_raw;
    };
    print STDOUT Template::Declare::Tags::show($code_template);

    return undef;
}

sub resolve_template { my $pkg =shift;  return Template::Declare->resolve_template(@_);}

1;
