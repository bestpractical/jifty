package Jifty::JSON;

use strict;
use base qw(Exporter);
use Jifty::JSON::Parser;
use Jifty::JSON::Converter;

@Jifty::JSON::EXPORT = qw(objToJson jsonToObj);

use vars qw($AUTOCONVERT $VERSION $UnMapping $BareKey $QuotApos
            $ExecCoderef $SkipInvalid $Pretty $Indent $Delimiter
            $KeySort $ConvBlessed);

$VERSION     = '1.02';

$AUTOCONVERT = 1;
$SkipInvalid = 0;
$ExecCoderef = 0;
$Pretty      = 0; # pretty-print mode switch
$Indent      = 2; # (for pretty-print)
$Delimiter   = 2; # (for pretty-print)  0 => ':', 1 => ': ', 2 => ' : '
$UnMapping   = 0; # 
$BareKey     = 0; # 
$QuotApos    = 0; # 
$KeySort     = undef; # Code-ref to provide sort ordering in converter

my $parser; # JSON => Perl
my $conv;   # Perl => JSON

##############################################################################
# CONSTRCUTOR - JSON objects delegate all processes
#                   to Jifty::JSON::Converter and Jifty::JSON::Parser.
##############################################################################

sub new {
    my $class = shift;
    my %opt   = @_;
    bless {
        conv   => undef,  # Jifty::JSON::Converter [perl => json]
        parser => undef,  # Jifty::JSON::Parser    [json => perl]
        # below fields are for Jifty::JSON::Converter
        autoconv    => $AUTOCONVERT,
        skipinvalid => $SkipInvalid,
        execcoderef => $ExecCoderef,
        pretty      => $Pretty     ,
        indent      => $Indent     ,
        delimiter   => $Delimiter  ,
        keysort     => $KeySort    ,
        convblessed => $ConvBlessed,
        # below fields are for Jifty::JSON::Parser
        unmapping   => $UnMapping,
        quotapos    => $QuotApos ,
        barekey     => $BareKey  ,
        # overwrite
        %opt,
    }, $class;
}


##############################################################################
# METHODS
##############################################################################

sub jsonToObj {
    my $self = shift;
    my $js   = shift;

    if(!ref($self)){ # class method
        my $opt = __PACKAGE__->_getParamsForParser($_[0]);
        $js = $self;
        $parser ||= new Jifty::JSON::Parser;
        $parser->jsonToObj($js, $opt);
    }
    else{ # instance method
        my $opt = $self->_getParamsForParser($_[0]);
        $self->{parser} ||= ($parser ||= Jifty::JSON::Parser->new);
        $self->{parser}->jsonToObj($js, $opt);
    }
}


sub objToJson {
    my $self = shift || return;
    my $obj  = shift;

    if(ref($self) !~ /Jifty::JSON/){ # class method
        my $opt = __PACKAGE__->_getParamsForConverter($obj);
        $obj  = $self;
        $conv ||= Jifty::JSON::Converter->new();
        $conv->objToJson($obj, $opt);
    }
    else{ # instance method
        my $opt = $self->_getParamsForConverter($_[0]);
        $self->{conv}
         ||= Jifty::JSON::Converter->new( %$opt );
        $self->{conv}->objToJson($obj, $opt);
    }
}


#######################


sub _getParamsForParser {
    my ($self, $opt) = @_;
    my $params;

    if(ref($self)){ # instance
        my @names = qw(unmapping quotapos barekey);
        my ($unmapping, $quotapos, $barekey) = @{$self}{ @names };
        $params = {
            unmapping => $unmapping, quotapos => $quotapos, barekey => $barekey,
        };
    }
    else{ # class
        $params = {
            unmapping => $UnMapping, barekey => $BareKey, quotapos => $QuotApos,
        };
    }

    if($opt and ref($opt) eq 'HASH'){
        for my $key ( keys %$opt ){
            $params->{$key} = $opt->{$key};
        }
    }

    return $params;
}


sub _getParamsForConverter {
    my ($self, $opt) = @_;
    my $params;

    if(ref($self)){ # instance
        my @names = qw(pretty indent delimiter autoconv keysort convblessed quotapos);
        my ($pretty, $indent, $delimiter, $autoconv, $keysort, $convblessed, $quotapos)
                                                           = @{$self}{ @names };
        $params = {
            pretty => $pretty, indent => $indent,
            delimiter => $delimiter, autoconv => $autoconv,
            keysort => $keysort, convblessed => $convblessed,
            quotapos => $quotapos,
        };
    }
    else{ # class
        $params = {
            pretty => $Pretty, indent => $Indent, delimiter => $Delimiter,
            keysort => $KeySort, convbless => $ConvBlessed,
            quotapos => $QuotApos,
        };
    }

    if($opt and ref($opt) eq 'HASH'){
        for my $key ( keys %$opt ){
            $params->{$key} = $opt->{$key};
        }
    }

    return $params;
}

##############################################################################
# ACCESSOR
##############################################################################

sub autoconv { $_[0]->{autoconv} = $_[1] if(defined $_[1]); $_[0]->{autoconv} }

sub pretty { $_[0]->{pretty} = $_[1] if(defined $_[1]); $_[0]->{pretty} }

sub indent { $_[0]->{indent} = $_[1] if(defined $_[1]); $_[0]->{indent} }

sub delimiter { $_[0]->{delimiter} = $_[1] if(defined $_[1]); $_[0]->{delimiter} }

sub unmapping { $_[0]->{unmapping} = $_[1] if(defined $_[1]); $_[0]->{unmapping} }

sub keysort { $_[0]->{keysort} = $_[1] if(defined $_[1]); $_[0]->{keysort} }

sub convblessed { $_[0]->{convblessed} = $_[1] if(defined $_[1]); $_[0]->{convblessed} }

##############################################################################
# NON STRING DATA
##############################################################################

# See Jifty::JSON::Parser for Jifty::JSON::NotString.

sub Number {
    my $num = shift;

    return undef if(!defined $num);

    if($num =~ /^-?(?:0|[1-9][\d]*)(?:\.[\d]*)?$/
               or $num =~ /^0[xX](?:[0-9a-zA-Z])+$/)
    {
        return bless {value => $num}, 'Jifty::JSON::NotString';
    }
    else{
        return undef;
    }
}

sub True {
    bless {value => 'true'}, 'Jifty::JSON::NotString';
}

sub False {
    bless {value => 'false'}, 'Jifty::JSON::NotString';
}

sub Null {
    bless {value => undef}, 'Jifty::JSON::NotString';
}

##############################################################################
1;
__END__

=pod

=head1 NAME

Jifty::JSON - parse and convert to JSON (JavaScript Object Notation).
This is a temporary fork of the L<JSON>.pm code to allow for outputting
single quotes.  I expect that the single-quote patch will go into
JSON.pm core in not too long, eliminating the need for this fork.

=cut
