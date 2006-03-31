use strict;
use warnings;

package Jifty::I18N;
use base 'Locale::Maketext';
use Locale::Maketext::Lexicon ();

=head1 NAME

Jifty::I18N - Internationalization framework for Jifty

=head1 METHODS

=head2 C<loc> /  C<_>

This module exports the C<loc> method, which it inherits from
L<Locale::Maketext::Simple>. Jifty aliases this method to C<_()> for 
your convenience.

=cut


sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    Locale::Maketext::Lexicon->import(
        {
        '*' => [
            Gettext => Jifty->config->framework('L10N')->{'PoDir'} . '/*.po',
            Gettext => Jifty->config->framework('L10N')->{'DefaultPoDir'} . '/*.po'
        ],
            
            _decode => 1,
        }
    );

    $Jifty::I18N::en::Lexicon{_AUTO} = 1;    # autocreate missing keys
    $self->init;

    my $lh         = eval { $class->get_handle };
    my $loc_method = sub  { $lh->maketext(@_); };
    no strict 'refs';
    *{ caller(0) . "::loc" } = $loc_method;
    *_ = \&{ caller(0) . "::loc" };
    warn "here for " . caller(0);
    return $self;
}

1;
