package Jifty::View::Declare;


use strict;
use warnings;
use constant BaseClassName => 'Jifty::View::Declare::BaseClass';

=head1 NAME

Jifty::View::Declare - Build views using Template::Declare

=head1 SYNOPSIS

    package MyApp::View;
    use Jifty::View::Declare -base;

    template 'index.html' => page {
        { title is 'Some Title' }
        b { "The Index" };
    };

=head1 DESCRIPTION

L<Template::Declare> is a templating system using a declarative syntax built on top of Perl. This provides a templating language built in a similar style to the dispatcher language in L<Jifty::Dispatcher>, the model language in L<Jifty::DBI::Schema>, and the action language in L<Jifty::Param::Schema>.

To use this view system, you must declare a class named C<MyApp::View> (where I<MyApp> is the name of your Jifty application). Use this library class to bring in all the details needed to make it work:

  package MyApp::View;
  use Jifty::View::Declare -base;

  # Your code...

For more details on how to write the individual templates, see L<Template::Declare> and also L<Jifty::View::Declare::Helpers> for Jifty specific details.

=cut

sub import {
    my ($class, $import) = @_;
    ($import and $import eq '-base') or return;
    no strict 'refs';
    my $pkg = caller;
    Jifty::Util->require(BaseClassName);
    push @{ $pkg . '::ISA' }, BaseClassName;

    strict->import;
    warnings->import;

    @_ = BaseClassName;
    goto &{BaseClassName()->can('import')};
}

=head1 SEE ALSO 

L<Jifty::View::Declare::Helpers>, L<Template::Declare>

=head1 LICENSE

Jifty is Copyright 2005-2010 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
