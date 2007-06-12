use warnings;
use strict;

=head1 NAME

TestApp::Plugin::News::View

=head1 DESCRIPTION


=cut

package TestApp::Plugin::News::View;
use Jifty::View::Declare -base;

use Jifty::Plugin::SiteNews::View::News;
alias Jifty::Plugin::SiteNews::View::News under '/news/';


1;
