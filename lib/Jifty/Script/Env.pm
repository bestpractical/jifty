package Jifty::Script::Env;

use warnings;
use strict;

use base qw/App::CLI::Command/;

use Scalar::Util ();

use Jifty::Config;
use Jifty::YAML;

=head1 NAME

Jifty::Script::Env - access the Jifty environment

=head1 DESCRIPTION

Loads Jifty and your configuration, allowing you to verify and examine
your setup.

=head2 run

  jifty env <Class> <method> [arguments]

Loads Jifty::Class and calls method on it, providing shortcuts for
things like:

  perl -MJifty::Util -e 'print Jifty::Util->share_root, "\n";'

The class and method can be combined with a '->' But, unquoted '>' is a
redirect so simply use the '-' or '.' characters.

  jifty env  Util share_root
  jifty env 'Util->share_root'
  jifty env  Util.share_root

You may chain accessors.  A leading dot also means the class is Jifty.

  jifty env Jifty.config.framework ApplicationName
  jifty env .config.framework ApplicationName

With no arguments, acts as 'C<jifty env Jifty.config.stash>'.

=cut

sub run {
    my $self = shift;
    my (@args) = @_;

    Jifty->new();

    unless(@args) {
        return($self->run('Jifty.config.stash'));
    }

    my ($class, $method, @and) = split(/(?:->?|\.)/, shift(@args));
    $class ||= 'Jifty';
    $method ||= shift(@args);

    my @ans;

    # enable Jifty.config.stash usage
    unless($class eq 'Jifty') {
        $class = 'Jifty::' . $class;
        eval("require $class") or die $@;
    }

    # walk down the chain of methods
    unshift(@and, $method);
    $method = pop(@and);
    while(my $attrib = shift(@and)) {
        $class = $class->$attrib;
    }

    @ans = $class->$method(@args);

    # if something in the answer is a reference, just dump
    if(grep({Scalar::Util::reftype($_)} @ans)) {
        print Jifty::YAML::Dump(\@ans);
    }
    else {
        print join("\n", @ans, '');
    }


} # end run

# original author:  Eric Wilhelm

1;
# vim:ts=4:sw=4:et:sta
