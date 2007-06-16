# XXX: unfortunately this requires some patches to B::Deparse so it
# won't work out of the box for you

use B::Deparse;
package B::Deparse;

my $oldbinop;
BEGIN {
    $oldbinop = B::Deparse->can('binop');
}

# nothing yet
sub binop {
    my $self = shift;
    my $ret = $oldbinop->($self, @_);
    if ($_[2] eq '=') {
    }
    return $ret;

}
package Jifty::View::Declare::Compile;
use strict;
use base 'B::Deparse';
use B qw(class main_root main_start main_cv svref_2object opnumber perlstring
	 OPf_WANT OPf_WANT_VOID OPf_WANT_SCALAR OPf_WANT_LIST
	 OPf_KIDS OPf_REF OPf_STACKED OPf_SPECIAL OPf_MOD
	 OPpLVAL_INTRO OPpOUR_INTRO OPpENTERSUB_AMPER OPpSLICE OPpCONST_BARE
	 OPpTRANS_SQUASH OPpTRANS_DELETE OPpTRANS_COMPLEMENT OPpTARGET_MY
	 OPpCONST_ARYBASE OPpEXISTS_SUB OPpSORT_NUMERIC OPpSORT_INTEGER
	 OPpSORT_REVERSE OPpSORT_INPLACE OPpSORT_DESCEND OPpITER_REVERSED
	 SVf_IOK SVf_NOK SVf_ROK SVf_POK SVpad_OUR SVf_FAKE SVs_RMG SVs_SMG
         CVf_METHOD CVf_LOCKED CVf_LVALUE CVf_ASSERTION
	 PMf_KEEP PMf_GLOBAL PMf_CONTINUE PMf_EVAL PMf_ONCE PMf_SKIPWHITE
	 PMf_MULTILINE PMf_SINGLELINE PMf_FOLD PMf_EXTENDED);

use constant method_invocation => '.';

sub padname {
    my $self = shift;
    my $targ = shift;
    return substr($self->padname_sv($targ)->PVX, 1);
}

require CGI;
our %TAGS = (
    map { $_ => +{} }
        map {@{$_||[]}} @CGI::EXPORT_TAGS{qw/:html2 :html3 :html4 :netscape :form/}
);

sub deparse {
    my $self = shift;
    my $ret = $self->SUPER::deparse(@_);
    return '' if $ret =~ m/use (strict|warnings)/;
    return $ret;
}

sub maybe_my {
    my $self = shift;
    my($op, $cx, $text) = @_;
    if ($op->private & OPpLVAL_INTRO and not $self->{'avoid_local'}{$$op}) {
	if (B::Deparse::want_scalar($op)) {
	    return "var $text";
	} else {
	    return $self->maybe_parens_func("my", $text, $cx, 16);
	}
    } else {
	return $text;
    }
}

sub maybe_parens_func {
    my $self = shift;
    my($func, $text, $cx, $prec) = @_;
    return "$func($text)";

}


sub _anoncode {
    my ($self, $text) = @_;
    return "function ()" . $text;
}

sub pp_entersub {
    my $self = shift;
    my $ret = $self->SUPER::pp_entersub(@_);
    $ret =~ s/return\s*\((.*)\)/return [$1]/ if $ret =~ m/^attr/;

    return $ret;
}

1;
