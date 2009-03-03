use strict;
use warnings;

package Jifty::Plugin::ViewDeclarePage;
use base qw/Jifty::Plugin/;

our $VERSION = '0.01';

=head1 NAME

Jifty::Plugin::ViewDeclarePage - sexy replacement for suckish Jifty::View::Declare::Page

=head1 DESCRIPTION

All you need you'll find in L<Jifty::Plugin::ViewDeclarePage::Page> doc.

Name sucks and I'm open for suggestions it's not late to rename.

=head1 METHODS

=head2 init

Called during initialization. Tries to load YourApp::View::Page that
is used by default as page implementation. If it's not there then
simple is generated, otherwise checked if your page class is sub
class of L<Jifty::Plugin::ViewDeclarePage::Page> and warning is issued
if it's not.

=cut

sub init {
    my $self = shift;
    my $class = Jifty->app_class('View::Page');
    if ( Jifty::Util->try_to_require($class) ) {
        Jifty->log->warn(
            "Plugin '". __PACKAGE__ ."' is used,"
            ." but class '$class' is not subclass of '". __PACKAGE__ ."::Page'"
        ) unless $class->isa( __PACKAGE__ .'::Page' );
    } else {
        my $page_class = __PACKAGE__ .'::Page';
        eval "package $class; use strict; use warnings; use base '$page_class'; 1;"
            or die $@;
        Jifty->log->debug("Generated simple '$class' class");
    }
    return 1;
}

=head1 LICENSE

Under the same terms as perl itself.

=head1 AUTHOR

Ruslan Zakirov E<lt>Ruslan.Zakirov@gmail.comE<gt>

=cut

1;
