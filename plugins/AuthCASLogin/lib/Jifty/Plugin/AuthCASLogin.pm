use strict;
use warnings;

=head1 NAME

Jifty::Plugin::AuthCASOnly

=head1 DESCRIPTION

B<MUST BE USED WITH Login PLUGIN>

Add cas users in L<Jifty::Plugin::Login::Model::User>. 
Distinct id for cas users is C<email> field with C<login@CAS.user>

=head1 CONFIG

 in etc/config.yml
  Plugins: 
    - Login: {}
    - AuthCASLogin: 
       CASserver: https://auth.univ-metz.fr
       CAFile: /home/agostini/univ.crt

=head1 SEE ALSO

L<AuthCAS>

=cut

package Jifty::Plugin::AuthCASLogin;
use base qw/Jifty::Plugin/;
use AuthCAS;

# Your plugin goes here.  If takes any configuration or arguments, you
# probably want to override L<Jifty::Plugin/init>.

{
    my $CAS;

    sub init {
        my $self = shift;
        my %args = @_;

    	my $cafile = $args{CAFile};
    	my $casserver = $args{CASserver};
    	$CAS = new AuthCAS(casUrl => $casserver, CAFile => $cafile);
    }

    sub CAS {
	   return $CAS;
    }
}

1;
