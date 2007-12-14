use strict;
use warnings;

=head1 NAME

TestApp::JiftyJS::Action::AddTwoNumbers

=cut

package TestApp::JiftyJS::Action::AddTwoNumbers;
use base qw/TestApp::JiftyJS::Action Jifty::Action/;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param first_number  => type is 'text';
    param second_number => type is 'text';
};

=head2 take_action

=cut

sub take_action {
    my $self = shift;
    my $one = $self->argument_value("first_number");
    my $two = $self->argument_value("second_number");
    $self->result->message("Got " . ($one + $two));
    return 1;
}

1;
