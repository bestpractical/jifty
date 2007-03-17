use strict;
use warnings;

=head1 NAME

 Jifty::Plugin::AuthCASOnly

=head1 DESCRIPTION

 MUST NOT BE USED WITH LOGIN PLUGIN

=head1 CONFIG

 in etc/config.yml
  Plugins: 
    - AuthCASOnly: 
       CASserver: https://auth.univ-metz.fr
       CAFile: /home/agostini/univ.crt
                    

=cut

package Jifty::Plugin::AuthCASOnly;
use base qw/Jifty::Plugin/;
use AuthCAS;

# Your plugin goes here.  If takes any configuration or arguments, you
# probably want to override L<Jifty::Plugin/init>.

{
    my ($CurrentCASUserClass, $AuthCASUserClass, $CAS);

    sub init {
        my $self = shift;
        my %args = @_;
        my $appname = Jifty->config->framework('ApplicationName');
        $CurrentCASUserClass = $args{CurrentUserClass}
            || "${appname}::CurrentUser";
        $AuthCASUserClass = $args{AuthCASUserClass}
            || "${appname}::Model::User";

	my ($conf, $cafile, $casserver);
    	foreach (@{Jifty->config->framework('Plugins')}) {
        	$conf = $_ if (defined $_->{'AuthCASOnly'});
    	}
    	$cafile = $conf->{'AuthCASOnly'}->{'CAFile'};
    	$casserver = $conf->{'AuthCASOnly'}->{'CASserver'};
    	$CAS = new AuthCAS(casUrl => $casserver,
                  CAFile => $cafile);
    }

    sub CurrentCASUserClass {
        return $CurrentCASUserClass;
    }

    sub AuthCASUserClass {
        return $AuthCASUserClass;
    }

    sub CAS {
	return $CAS;
    }
}

1;
