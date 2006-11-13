package Jifty::View::Declare::Handler;

use warnings;
use strict;

use base qw/Jifty::Object Class::Accessor/;

__PACKAGE__->mk_accessors(qw/root_class/);

=head2 show $package $template

=cut

sub show {
    my $self = shift;
    my $package = shift;
    my $template = shift;
        no warnings qw/redefine/;
        local *{Jifty::Web::out} = sub { shift; my $out = shift; Template::Declare::Tags::outs( $out);};
    local $Template::Declare::Tags::BUFFER = '';
    print STDOUT $package->show($template);
    return undef;
}

=head2 resolve_template template_path

Takes the path of a template
to resolve. Checks to make sure it's a valid template, resolves the
template name and package to an exact package and the name of the
template within that package. Returns undef if it can't resolve the
template.



For example:

    admin/users/new

would become 

    Wifty::UI::admin::users, new


=cut


sub resolve_template {
    my $self         = shift;
    my $templatename = shift;    # like /admin/ui/new

    my @components = split( '/', $templatename );
    my $template   = pop @components;

    my $package =  join('::',$self->root_class,grep { $_ } @components);
    Jifty::Util->require($package);
    unless ( $package->isa('Jifty::View::Declare::Templates') ) {
        $self->log->error( "$package (" . $self->root_class . " / $templatename) isn't a valid template package." );
        return undef;
    }
    unless ( $package->can('has_template') &&  $package->has_template($template) ) {
        $self->log->error("$package has no template $template.");
        return undef;

    }

    return ( $package, $template );

}

1;

