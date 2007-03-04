package Jifty::View::Declare::Handler;

use warnings;
use strict;

use base qw/Jifty::Object Class::Accessor/;
use Template::Declare;


__PACKAGE__->mk_accessors(qw/root_class/);

=head1 NAME

Jifty::View::Declare::Handler

=head1 METHODS


=head2 new


Initialize C<Template::Declare>. Passes all arguments to Template::Declare->init

=cut


sub new {
    my $class = shift;
    my $self = {};
    bless $self,$class;
    warn "Initting T::D with ". YAML::Dump(\@_);
    Template::Declare->init(@_);
    return $self;
}


=head2 show TEMPLATENAME

Render a template. Expects that the template and any jifty methods called internally will end up being returned as a scalar, which we then print to STDOUT


=cut

sub show {
    my $self          = shift;
    my $template = shift;

    no warnings qw/redefine utf8/;
    local *Jifty::Web::out = sub {
        shift;    # Turn the method into a function
        goto &Template::Declare::Tags::outs_raw;
    };
    my $content =Template::Declare::Tags::show($template);
        unless ( Jifty->handler->apache->http_header_sent ||Jifty->web->request->is_subrequest ) {
            Jifty->handler->apache->send_http_header();
        }
    print STDOUT $content;
    return undef;
}

=head2 template_exists TEMPLATENAME

Given a template name, returns true if the template is in any of our Template::Declare template libraries. Otherwise returns false.

=cut

sub template_exists { my $pkg =shift;  
warn "Checking for ".join(',',@_);

return Template::Declare->resolve_template(@_);}

1;
