use strict;
use warnings;

package Jifty::Plugin::IEFixes;
use base 'Jifty::Plugin';

=head1 NAME

Jifty::Plugin::IEFixes - Add javascript files for IE

=head1 SYNOPSIS

# In your jifty config.yml under the framework section:

  Plugins:
    - IEFixes:
        use_external_ie7js: 1
        js:
          - IE7
          - IE8
          - ie7-recalc
          - ie7-squish


  In your app, if you want to add more IE-specific js:

    my ($ief) = Jifty->find_plugin('Jifty::Plugin::IEFixes')
    $ief->add_javascript( qw(file.js) );

=cut

__PACKAGE__->mk_accessors(qw(use_external_ie7js js user_js));

use constant IE7JS_VERSION => '2.0(beta3)';

=head1 METHODS

=head2 init

Outputs IE-specific "conditional comments" in the C<< <head> >> of
each response which include more javascript.

=cut

sub init {
    my $self = shift;
    return if $self->_pre_init;

    my %opt  = @_;
    $self->use_external_ie7js( $opt{ use_external_ie7js } );
    $self->user_js([]);
    # default is just IE7.js
    my @base_js = @{ $opt{ js } || ['IE7'] };

    Jifty::Web->add_trigger(
        name     => 'after_include_javascript',
        callback => sub {
            Jifty->web->out(qq{<!--[if lt IE 7]>\n});
            if ($self->use_external_ie7js) {
                Jifty->web->out(qq{<script src="http://ie7-js.googlecode.com/svn/version/@{[ IE7JS_VERSION ]}/$_.js" type="text/javascript"></script>\n}) for @base_js;
            }
            else {
                # XXX: make ccjs able to cope with this as a separate CAS object
                Jifty->web->out(qq{<script type="text/javascript" src="@{[ Jifty->web->static(qq{js/iefixes/$_.js}) ]}" type="text/javascript"></script>\n})
                    for @base_js;

                Jifty->web->out(qq{<script type="text/javascript" src="@{[ Jifty->web->static(qq{js/$_}) ]}" type="text/javascript"></script>\n})
                    for @{ $self->user_js };
            }
            Jifty->web->out(qq{<![endif]-->\n});
        }
    );

}

=head2 add_javascript FILE

Can be called during application initialization (at startup time) to
add more javascript which should only be included in IE browsers.  See
also L<Jifty::Web/add_javascript>.

=cut

sub add_javascript {
    my $self = shift;
    push @{ $self->user_js }, @_;
}



1;
