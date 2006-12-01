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
    my $code_template = shift;

    no warnings qw/redefine utf8/;
    local *Jifty::Web::out = sub {
        shift;  # Remove the $self in Jifty::Web->out
        goto &Template::Declare::Tags::outs;
    };

    local $Template::Declare::Tags::BUFFER = '';
    print STDOUT $package->show($code_template);
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

    Wifty::View::admin::users, new


=cut


sub resolve_template {
    my $self          = shift;
    my $template_name = shift;    # like /admin/ui/new

    my @components = split( '/', $template_name );
    my $template   = pop @components;
    my $package;

    REQUIRE_PACKAGE: {
        $package = join('::', $self->root_class, grep { $_ } @components);
        $package->require;

        if ($UNIVERSAL::require::ERROR =~ /^Can't locate/) {
            $self->log->debug($UNIVERSAL::require::ERROR);

            # It's possible that /admin/ui/new is defined in admin, instead of admin::ui
            if (@components) {
                $template = pop(@components) . '/' . $template;
                redo REQUIRE_PACKAGE;
            }

            return undef;
        }
    }

    unless ( $package->isa('Jifty::View::Declare::Templates') ) {
        $self->log->error( "$package (" . $self->root_class . " / $template_name) isn't a valid template package." );
        return undef;
    }

    if ( $package->can('has_template') and my $code_template = $package->has_template($template) ) {
        return ( $package, $code_template );
    }
    else {
        $self->log->warn("$package has no template $template.");
        return undef;
    }
}

1;
