use strict;
use warnings;

package Jifty::Plugin::CSSQuery;
use base qw/ Jifty::Plugin /;

=head1 NAME

Jifty::Plugin::CSSQuery - use the cssQuery JavaScript library with Jifty

=head1 SYNOPSIS

In your F<etc/config.yml>:

  framework:
    Plugins:
      - CSSQuery: {}

=head1 DESCRIPTION

cssQuery() is a powerful cross-browser JavaScript function that
enables querying of a DOM document using CSS selectors. All CSS1 and
CSS2 selectors are allowed plus quite a few CSS3 selectors.

This is a Jifty plugin that let you use cssQuery javascript library in
your Jifty application. cssQuery has been bundle with Jifty for a long
time, for Jifty use it internally. Now it's been replaced with jQuery.
It's now a plugin for backward compatibility.

It is disabled by default, unless your C<ConfigFileVersion> is smaller
or equal then 2.

For more information about cssQuery, see L<http://dean.edwards.name/my/cssQuery/>.

=head1 METHODS

=head2 init

This initializes the plugin, which simply includes the JavaScript
necessary to load cssQuery, and gets rid of the cssQuery-jquery back-compat
script.

=cut

sub init {
    Jifty->web->remove_javascript(
        'cssQuery-jquery.js',
    );

    Jifty->web->add_javascript(
        'cssquery/cssQuery.js',
        'cssquery/cssQuery-level2.js',
        'cssquery/cssQuery-level3.js',
        'cssquery/cssQuery-standard.js'
    );
}

=head1 SEE ALSO

L<http://jifty.org>, L<http://dean.edwards.name/my/cssQuery/>

=head1 COPYRIGHT AND LICENSE

This plugin is Copyright 2007 Handlino, Inc.

It is available for modification and distribution under the same terms
as Perl itself.

cssQuery is available for use in all personal or commercial projects
under both MIT and GPL licenses. This means that you can choose the
license that best suits your project and use it accordingly. See
L<http://jifty.com/> for current information on cssQuery copyrights
and licensing.

=cut

1;
