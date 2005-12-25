use warnings;
use strict;

package JFDI::Everything;

=head1 NAME

JFDI::Everything - Load all of the JFDI modules

=cut

# Could use Module::Pluggable, I guess.

use JFDI;

use JFDI::Action;
use JFDI::Action::Record;
use JFDI::Action::Record::Create;
use JFDI::Action::Record::Update;

use JFDI::Collection;

use JFDI::Handler;

use JFDI::MasonInterp;

use JFDI::Model::Schema;

use JFDI::Object;

use JFDI::Record;

use JFDI::Request;
use JFDI::Result;
use JFDI::Response;

# We can _not_ load Server.pm unless we're in a Server context because
# HTTP::Server::Simple::Mason bastardizes HTML::Mason::FakeApache::send_http_header
# with hook::lexwrap
#use JFDI::Server;

use JFDI::Test;

use JFDI::View::Helper;

use JFDI::Web;
use JFDI::Web::Form;
use JFDI::Web::Form::Field;
use JFDI::Web::Menu;

use Module::Pluggable;
Module::Pluggable->import(search_path => ['JFDI::Web::Form::Field', 'JFDI::View::Helper', 'JFDI::Callback'], require => 1);
__PACKAGE__->plugins;

1;

