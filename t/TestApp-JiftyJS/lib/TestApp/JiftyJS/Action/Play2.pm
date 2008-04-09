use strict;
use warnings;

=head1 NAME

TestApp::JiftyJS::Action::Play2

=cut

package TestApp::JiftyJS::Action::Play2;
use base qw/TestApp::JiftyJS::Action Jifty::Action/;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param bogus => type is 'text';
};

=head2 take_action

=cut

sub take_action {
    my $self = shift;
    # Custom action code
    $self->report_success if not $self->result->failure;
    return 1;
}

=head2 report_success

=cut

sub report_success {
    my $self = shift;
    # Your success message here
    $self->result->message('Success');
}

1;

