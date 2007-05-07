use strict;
use warnings;

package Jifty::Plugin::DumpDispatcher;
use base qw/Jifty::Plugin/;

=head1 NAME

Jifty::Plugin::DumpDispatcher

=head1 DESCRIPTION

When activated in C<config.yml> with:

  Plugins:
    - DumpDispatcher: {}

it will dump all dispatcher rules in debug log.

=head2 dump_rules

Dump all defined rules in debug log. It is called by Jifty, after
C<< Jifty->dispatcher->import_plugins >> on startup.

=cut

sub dump_rules {
    my $self = shift;
	#my %args = @_;

    no strict 'refs';
    foreach my $stage ( qw/SETUP RUN CLEANUP/ ) {

		my $rules = Jifty->app_class( 'Dispatcher' ) . '::RULES_' . $stage;

        Jifty->log->debug( "Dispatcher rules in stage $stage:");
		Jifty->log->debug( _unroll_dumpable_rules( 0, $_ ) ) foreach @{ $rules }

    }
};

=head2 _unroll_dumpable_rules LEVEL,RULE

Walk all rules defined in dispatcher starting at rule
C<RULE> and indentation level C<LEVEL>

=cut

sub _unroll_dumpable_rules {
    my ($level, $rule) = @_;
    my $log = 
        # indentation
        ( "    " x $level ) .
        # op
        ( $rule->[0] || "undef op" ) . ' ' .
        # arguments
        (
            ! defined( $rule->[1] )   ? ""                                          :
            ref $rule->[1] eq 'ARRAY' ? "'" . join("','", @{ $rule->[1] }) . "'" :
            ref $rule->[1] eq 'HASH'  ? $rule->[1]->{method} . " '" . $rule->[1]->{""} ."'" :
            ref $rule->[1] eq 'CODE'  ? '{...}' :
                                        "'" . $rule->[1] . "'"
        );

    if (ref $rule->[2] eq 'ARRAY') {
        $level++;
        foreach my $sr ( @{ $rule->[2] } ) {
            $log .=   _unroll_dumpable_rules( $level, $sr );
        }
    }
    return $log;
}

1;
