use warnings;
use strict;

package Jifty::MasonInterp;

use base qw/HTML::Mason::Interp Jifty::Object/;

=head2 make_request

Overrides L<HTML::Mason::Interp>'s C<make_request> to call C<jifty_munge_args>
on the request arguments and to log the execution (at debug level).

=cut

sub make_request {
    my $self = shift;
    my %p = @_; 
    # %p is parameters to make_request
    # $p{'args'} is an arrayref that becomes %ARGS in Mason

    my $comp_args = { @{ $p{'args'} } };
    $self->jifty_munge_args($comp_args); # modifies $comp_args
    $p{'args'} = [ %$comp_args ];
    
    # This is disabled in the logging conf files; comment out the MasonInterp
    # line if you want it back.
    $self->log->debug("Executing '$p{'comp'}' with args: ", {filter=>\&YAML::Dump, value=> $comp_args});


    return $self->SUPER::make_request(%p);
}

=head2 jifty_munge_args PARAMS

Takes a hashref PARAMS; does argument munging to it (modifying the contents
of the reference passed in).

The currently defined munging is to take arguments with a B<name> of

   bla=bap|beep=bop|foo=bar

and an arbitrary value, and make it appear as if they were actually
separate arguments.  The point is that we might want submit buttons to act as if
they'd sent multiple values, without using JavaScript.

For now, if multiple splittable args specify the same name, or a splittable arg and
a normal arg specifies a name, exactly one of the splittable args is used (which one
is not defined); they are not combined into arrays or hashes or anything.  This might
be poor behavior; avoid doing this.

=cut


sub jifty_munge_args {
    my $self = shift;
    my $args = shift;

    # Pull out all the splittable names at once, since we'll be deleting
    my @splittable_names = grep /=|\|/, keys %$args;

    for my $splittable (@splittable_names) {
        delete $args->{$splittable};

        for my $newarg (split /\|/, $splittable) {
            # If there are multiple =s, you just lose.
            my ($k, $v) = split /=/, $newarg;
            $args->{$k} = $v;
        } 
    } 
} 

1;
