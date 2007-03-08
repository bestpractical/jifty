use warnings;
use strict;

package Jifty::Plugin::SkeletonApp::Dispatcher;

=head1 NAME

Jifty::Plugin::SkeletonApp::Dispatcher

=head1 DESCRIPTION

When a user asks for /, give them index.html.

=cut


use Jifty::Dispatcher -base;

on '/' => run { show 'index.html' };

1;
