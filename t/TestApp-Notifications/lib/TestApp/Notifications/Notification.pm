package TestApp::Notifications::Notification;
use base 'Jifty::Notification';
use strict;
use warnings;

sub subject { 'testapp-notifications' }
sub from { 'notifications@localhost' }
sub recipients { 'recipient@localhost' }

1;

