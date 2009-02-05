package Jifty::View::Declare::Handler;

use warnings;
use strict;

use base qw/Jifty::View Class::Accessor::Fast/;
use Template::Declare;

use HTML::Mason::Exceptions;
use Exception::Class ( 'Template::Declare::Exception' =>
    {description => 'error in a Template::Declare template', alias => 'error'});

__PACKAGE__->mk_accessors(qw/root_class/);

=head1 NAME

Jifty::View::Declare::Handler - The Jifty view handler for Template::Declare

=head1 METHODS


=head2 new


Initialize C<Template::Declare>. Passes all arguments to Template::Declare->init

=cut


sub new {
    my $class = shift;
    my $self = {};
    bless $self,$class;
   
    Template::Declare->init(@_ || $self->config());
    return $self;
}


=head2 config

=cut

sub config {
    
    my %config = (
        %{ Jifty->config->framework('Web')->{'TemplateDeclareConfig'} ||{}},
    );

    for my $plugin ( Jifty->plugins ) {
        my $comp_root = $plugin->template_class;
        Jifty::Util->require($comp_root);
        next unless (defined $comp_root and $comp_root->isa('Template::Declare') and not Jifty::ClassLoader->autogenerated($comp_root));
        $plugin->log->debug( "Plugin @{[ref($plugin)]}::View added as a Template::Declare root");
        push @{ $config{roots} }, $comp_root ;
    }

    push @{$config{roots}},  Jifty->config->framework('TemplateClass');
    return %config;
}

=head2 show TEMPLATENAME

Render a template. Expects that the template and any jifty methods
called internally will end up being returned as a scalar, which we
then print to STDOUT


=cut

sub show {
    my $self     = shift;
    my $template = shift;

    Template::Declare->buffer( Jifty->handler->buffer );
    eval {
        Template::Declare::Tags::show_page( $template, { %{Jifty->web->request->arguments}, %{Jifty->web->request->template_arguments || {}} } );
    };
    if (my $err = $@) {
        $err->rethrow if ref $err;
        Template::Declare::Exception->throw($err);
    }
    return;
}

=head2 template_exists TEMPLATENAME

Given a template name, returns true if the template is in any of our
Template::Declare template libraries. Otherwise returns false.

=cut

sub template_exists {
    my $pkg =shift;
    return Template::Declare->resolve_template(@_);
}

package HTML::Mason::Exception;
no warnings 'redefine';

sub template_stack {
    my $self = shift;
    unless ($self->{_stack}) {
        $self->{_stack} = [reverse grep defined $_, map {$_->{from}} @{Jifty->handler->buffer->{stack}}],
    }
    return $self->{_stack};
}

sub as_text
{
    my ($self) = @_;
    my $msg = $self->full_message;
    my @template_stack = @{$self->template_stack};
    if (@template_stack) {
        my $stack = join("\n", map { sprintf("  [%s]", $_) } @template_stack);
        return sprintf("%s\nTemplate stack:\n%s\n", $msg, $stack);
    } else {
        my $info = $self->analyze_error;
        my $stack = join("\n", map { sprintf("  [%s:%d]", $_->filename, $_->line) } @{$info->{frames}});
        return sprintf("%s\nStack:\n%s\n", $msg, $stack);
    }
}

package Template::Declare::Exception;
our @ISA = 'HTML::Mason::Exception';

1;
