use warnings;
use strict;

=head1 NAME

Jifty::Plugin::AuthzLDAP::Action::LDAPValidate - action to validate filter

=cut

package Jifty::Plugin::AuthzLDAP::Action::LDAPValidate;
use base qw/Jifty::Action Jifty::Plugin::AuthzLDAP/;

our $VERSION = '0.01';

=head2 arguments

Return the ticket form field

=cut

sub arguments {
    return (
        {
            name => {
                mandatory      => 1
            },

            filter => {
                mandatory => 1
            },

        }
    );

}

=head2 take_action

Bind on ldap to check the user's password. If it's right, log them in.
Otherwise, throw an error.


=cut

sub take_action {
    my $self = shift;
    my $user = $self->argument_value('name');
    my $filter = $self->argument_value('filter');

    Jifty->log->debug("action: $user $filter");

    # Bind on ldap
    #my $msg = $self->bind();
    
    my $msg = $self->ldapvalidate($user,$filter);

    Jifty->log->debug("validate: $msg");

    if (not $msg) {
        $self->result->error(
            _('Access denied.') );
        return;}

    return 1;
}

=head1 AUTHOR

Yves Agostini, <yvesago@cpan.org>

=head1 LICENSE

Copyright 2007-2008 Yves Agostini. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;


