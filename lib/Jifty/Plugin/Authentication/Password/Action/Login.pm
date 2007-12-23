use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Authentication::Password::Action::Login

=cut

package Jifty::Plugin::Authentication::Password::Action::Login;
use base qw/Jifty::Action/;
use Digest::MD5 qw(md5_hex);

use constant TOKEN_EXPIRE_TIME => 30;

=head2 arguments

Return the email and password form fields

=cut

sub arguments { 
    return( { email => { label => _('Email'),
                           mandatory => 1,
                           ajax_validates => 1,
                            }  ,

              password => { type => 'password',
                            label => _('Password'),
			    # mandatory in some cases; see validate_password
                            mandatory => 0,
                        },
              hashed_password => { type => 'hidden',
                            label => _('Hashed Password'),
                        },
              remember => { type => 'checkbox',
                            label => _('Remember me?'),
                            hints => _('Your browser can remember your login for you'),
                            default => 0,
                          },
	      token => { type => 'hidden',
			 label => 'token',
			 mandatory => 0 },

          });

}

=head2 validate_email ADDRESS

Makes sure that the email submitted is a legal email and that there's a user in the database with it.

Overridden from Jifty::Action::Record.

=cut

sub validate_email {
    my $self  = shift;
    my $email = shift;

    my $u = $self->load_user($email);
    return $self->validation_error(email => _("It doesn't look like there's an account by that name.")) unless ($u->id);

    return $self->validation_ok('email');
}


=head2 validate_password PASSWORD

Makes sure that the password submitted actually exists, unless there's a token and a hashed
password.

Overridden from Jifty::Action::Record.

=cut

sub validate_password {
    my $self  = shift;
    my $pw = shift;
    my $token =  $self->argument_value('token') ||'';
    my $hashedpw =  $self->argument_value('hashed_password') ;


    if ($token eq '') { # we have no token, validate in a standard way
        unless ( defined $pw && length $pw ) {
            return $self->validation_error(password => "Please fill in this field." );
        }
    } else { # we have a token, so we should have a hashed pw
        my $emptypw = '';
        my $blankhash = md5_hex("$token $emptypw");
        if ($hashedpw eq $blankhash) {
            return $self->validation_error(password => "Please fill in this field." );
        }
        
    }


    return $self->validation_ok('password');
}

=head2 validate_token TOKEN

Make sure we issued the token within the last 30 seconds, otherwise
time out the request.

=cut

sub validate_token {
    my $self = shift;
    my $value = shift;
    if ($value) {
        if(int $value < (time - TOKEN_EXPIRE_TIME)) { 
            return $self->validation_error(token => "Your login attempt has timed out. Please try again.");
        }
        if ($value ne Jifty->web->session->get('login_token')) {
            return $self->validation_error(token => "That didn't work. Please try again.");
        }
        Jifty->web->session->set(login_token => '');
    }
    return $self->validation_ok("token");
}

=head2 take_action

Actually check the user's password. If it's right, log them in.
Otherwise, throw an error.


=cut

sub take_action {
    my $self = shift;
    my $user = $self->load_user( $self->argument_value('email') );
    my $password = $self->argument_value('password');
    my $token    = $self->argument_value('token') || '';
    my $hashedpw = $self->argument_value('hashed_password');


    if ( $token ne '' ) {   # browser supports javascript, do password hashing
        unless ( $user->id && $user->hashed_password_is( $hashedpw, $token ) )
        {
            $self->result->error( _('You may have mistyped your email or password. Give it another shot.'));
            return;
        }
        Jifty->web->session->set( login_token => '' );
    } else {                # no password hashing over the wire
        unless ( $user->id && $user->password_is($password) ) {
            $self->result->error( _('You may have mistyped your email or password. Give it another shot.'));
            return;
        }
    }
    unless ($user->email_confirmed) {
                $self->result->error( _(q{You haven't confirmed your account yet.}) );        return;
                    }

    # Set up our login message
    $self->result->message( $self->login_message($user));
    $self->result->content( id => $user->id );

    # Actually do the signin thing.
    Jifty->web->current_user(Jifty->app_class('CurrentUser')->new( id => $user->id));
    Jifty->web->session->expires( $self->argument_value('remember') ? '+1y' : undef );
    Jifty->web->session->set_cookie;

    return 1;
}

=head2 load_user

Load up and return a YourApp::User object for the user trying to log in

=cut

sub load_user {
    my $self = shift;
    my $username = shift;
    my $user = Jifty->app_class('Model', 'User')->new(current_user => Jifty->app_class('CurrentUser')->superuser);
    $user->load_by_cols( email => $username);
    return $user

}

=head2 login_message $user_object

Returns the "hi, you're logged in message"

=cut


sub login_message {
    my $self = shift;
    my $user = shift;
    return _("Welcome back, %1.", $user->name);
}

1;
