use strict;
use warnings;

package Jifty::Plugin::JQuery;
use base qw/ Jifty::Plugin /;

=head1 NAME

Jifty::Plugin::JQuery - use the jQuery JavaScript library with Jifty

=head1 SYNOPSIS

In your F<etc/config.yml>:

  framework:
    Plugins:
      - JQuery: {}

In your JavaScript files, you can then use any jQuery call:

  jQuery("p.surprise").addClass("ohmy").show("slow");

=head1 DESCRIPTION

The jQuery JavaScript library is a small JavaScript library with the intent of providing most of the shortcuts you need it a simple syntax. Since Jifty already uses Prototype, which implements a C<$()> function, this plugin loads jQuery and calls "C<noConflict()>" to prevent it from clobbering Prototype's C<$()> function. Thus, to use jQuery, you have to use the C<jQuery()> method rather than C<$()>.

You may want to use this idiom from the jQuery documentation if you still want to use this idiom (see L<http://docs.jquery.com/Using_jQuery_with_Other_Libraries>): 

  function($){
     // Use jQuery stuff using $
     $("div").hide();
  }(jQuery);

=head1 METHODS

=head2 init

This initializes the plugin, which simply includes the JavaScript necessary to load jQuery and then disable the jQuery implementation of C<$()>.
  
=cut

sub init {
    Jifty->web->add_javascript(qw/
        jquery.js
        noConflict.js
    /);
}

=head1 SEE ALSO

L<http://jifty.org>, L<http://visualjquery.com>, L<http://simonwillison.net/2007/Aug/15/jquery/>

=head1 COPYRIGHT AND LICENSE

This plugin is Copyright 2007 Boomer Consulting, Inc. It is available for modication and distribution under the same terms as Perl itself.

jQuery is available for use in all personal or commercial projects under both MIT and GPL licenses. This means taht you can choose the license that best suits your project and use it accordingly. See L<http://jifty.com/> for current information on jQuery copyrights and licensing.

=cut

1;
