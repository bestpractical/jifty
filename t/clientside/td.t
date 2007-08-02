#!/usr/bin/env perl
use strict;
use warnings;
use Jifty;

package Foo;
use Jifty::View::Declare -base;

template _faq => \&_faq;

sub _faq {
    div {
        attr { id => "faq" };
        h2 { 'Using Yada' }
        dl {
            dt { 'Yada Yada Yada!'}
            dd {
                span {
                    'are we nearly there yet?'
                }
	    }
	};
    }
};

template _faq2 => \&_faq2;

sub _faq2 {
    div {
        attr { id => "faq" };
        h2 { 'Using Yada' }
        dl {
            dt { 'Yada Yada Yada!'};
            dd {
                span {
                    'are we nearly there yet?'
                }
	    }
	};
    }
};

package main;

use Test::More;
use IPC::Run3;
eval 'use Jifty::View::Declare::Compile; 1'
    or plan skip_all => "Can't load Jifty::View::Declare::Compile";

my $jsbin = can_run('js')
    or plan skip_all => "Can't find spidermonkey js binary";

Template::Declare->init( roots => ['Foo']);

plan tests => 2;

is_compatible('_faq');
TODO: {
local $TODO = 'buf handling (non-katamari version) not yet';
is_compatible('_faq2');

};



sub is_compatible {
    my $template = shift;
    my $js = js_output( js_code( Foo->can($template) ) );
    my $td = Template::Declare->show($template);
    $js =~ s/\s*//g;
    $td =~ s/\s*//g;
    unshift @_, $js, $td;
    goto \&is;
}

sub js_code {
    my $code = shift;
    return '(function() '.Jifty::View::Declare::Compile->new->coderef2text($code) . ')()';
}

sub js_output {
    my $code = shift;
    my ($out, $err);
    run3 [$jsbin],
	['load("share/web/static/js/template_declare.js");', "print($code);"],
	    \$out, \$err;
    diag $err if $err;
    return $out;

}

use File::Spec::Functions 'catfile';
sub can_run {
    my ($_cmd, @path) = @_;

    return $_cmd if -x $_cmd;

    for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), @path, '.') {
        my $abs = catfile($dir, $_[0]);
        return $abs if -x $abs;
    }

    return;
}
