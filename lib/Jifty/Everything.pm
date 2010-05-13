use warnings;
use strict;

package Jifty::Everything;

=head1 NAME

Jifty::Everything - Load all of the important Jifty modules at once.

=head1 DESCRIPTION

This package is loaded very early in the processof loading Jifty to bring in all of the wonderful goodies that make up Jifty. If you use L<JIfty>:

  use Jifty;

you use this package, so you should not need to use it yourself in most circumstances.

=cut

use Cwd ();
BEGIN {
    # Cwd::cwd() insists doing `pwd`, which is a few hundreds of shell
    # outs just in the BEGIN time for Module::Pluggable to load things.
    if ($^O ne 'MSWin32') {
        require POSIX;
        *Cwd::cwd = *POSIX::getcwd;
    }
}

use Jifty ();
use Jifty::I18N ();
use Jifty::Dispatcher ();
use Jifty::Object ();
use Jifty::Config ();
use Jifty::Handle ();
use Jifty::ClassLoader ();
use Jifty::Util ();
use Jifty::API ();
use Jifty::DateTime ();
use Jifty::Record ();
use Jifty::Collection ();
use Jifty::Action ();
use Jifty::Action::AboutMe ();
use Jifty::Action::Autocomplete ();
use Jifty::Action::Redirect ();
use Jifty::Action::Record ();
use Jifty::Action::Record::Create ();
use Jifty::Action::Record::Update ();
use Jifty::Action::Record::Delete ();


use Jifty::Continuation ();

use Jifty::LetMe ();

use Jifty::Logger ();
use Jifty::Handler ();
use Jifty::View::Static::Handler ();
use Jifty::View::Declare::Handler ();
use Jifty::View::Mason::Handler ();

use Jifty::Model::Metadata ();
use Jifty::Model::Session ();
use Jifty::Model::SessionCollection ();


use Jifty::Request ();
use Jifty::Request::Mapper ();
use Jifty::Result ();
use Jifty::Response ();
use Jifty::CurrentUser ();

use Jifty::Web ();
use Jifty::Web::Session ();
use Jifty::Web::PageRegion ();
use Jifty::Web::Form ();
use Jifty::Web::Form::Clickable ();
use Jifty::Web::Form::Element ();
use Jifty::Web::Form::Link ();
use Jifty::Web::Form::Field ();
use Jifty::Web::Menu ();

use Jifty::Subs ();
use Jifty::Subs::Render ();

use Jifty::CAS ();

use Jifty::Module::Pluggable;
#Jifty::Module::Pluggable->import(search_path => ['Jifty::Web::Form::Field'], require     => 1, except      => qr/\.#/);
#__PACKAGE__->plugins;

# Set up to load commands defined in Jifty/Plugin/*/Command/*.pm
# we do the actual load in Jifty::Script
Jifty::Module::Pluggable->import(
    search_path => ['Jifty::Plugin'],
    file_regex  => qr{/Command/[^/]+\.pm},
    require     => 1,
    sub_name    => "plugin_commands",
);

=head1 SEE ALSO

L<Jifty>

=head1 LICENSE

Jifty is Copyright 2005-2007 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
