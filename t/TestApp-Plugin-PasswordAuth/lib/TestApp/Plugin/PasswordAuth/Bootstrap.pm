use warnings;
use strict;
package TestApp::Plugin::PasswordAuth::Bootstrap;


 use base 'Jifty::Bootstrap';
 
sub run {
    my $curuser = TestApp::Plugin::PasswordAuth::CurrentUser->new( _bootstrap => 1 );
    my $user = TestApp::Plugin::PasswordAuth::Model::User->new( current_user => $curuser );
    my ($val,$msg) = $user->create( username => 'gooduser@example.com',
                                            color => 'gray',
                                                                   swallow_type => 'african',
                                                                                          password => 'secret'

);


}

1;
