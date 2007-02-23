package Jifty::View::Declare::CoreTemplates;

use strict;
use warnings;
use vars qw( $r );

use Jifty::View::Declare -base;

use Scalar::Defer;

sub __jifty::online_docs::autohandler {

# If "AdminMode" is turned off in Jifty's config file, don't let people at the admin UI.
    unless ( Jifty->config->framework('AdminMode') ) {
        $m->redirect('/__jifty/error/permission_denied');
        $m->abort();
    }

    $m->call_next();
}

                                sub '__jifty::online_docs::content . html' {
                                    <?xml version="1.0" encoding="UTF-8"?> <
                                      !DOCTYPE html PUBLIC
                                      "-//W3C//DTD XHTML 1.1//EN"
"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
                                      > <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" >
                                      < head > <title> <
                                      %_ ( $n || 'Jifty' ) % >
                                      -<%_('Jifty Pod Online')%> < /title>
<style type="text/css"><!--
a { text-decoration: none }
a:hover { text-decoration: underline }
a:focus { background: #99ff99; border: 1px black dotted }
--></style>
</head>
body {
<%PERL>
my $jifty_dirname = Jifty::Util->jifty_root." / ";
my $app_dirname = Jifty::Util->app_root." / lib /";
$n =~ s/ :: /\//g;

                                    my @options = (
                                        $app_dirname . $n . ".pod",
                                        $app_dirname . $n . ".pm",
                                        $jifty_dirname . $n . ".pod",
                                        $jifty_dirname . $n . ".pm"
                                    );

                                    my $total_body;
                                    foreach my $file (@options) {
                                        next unless -r "$file";
                                        local $/;
                                        my $fh;
                                        open $fh, "$file" or next;
                                        $total_body = <$fh>;
                                        close $fh;
                                    }
                                    my $body;
                                    my $schema;
                                    my $converter = Pod::Simple::HTML->new();
                                    if ( $n !~ /^Jifty\// ) {
                                        if ( $total_body =~
/package (.*?)::Schema;(.*)package/ismx
                                          )
                                        {
                                            $schema = $2;
                                        }
                                    }

                                    $converter->output_string( \$body );
                                    $converter->parse_string_document(
                                        $total_body);
                                    $body =~ s{.*?<body [^>]+>}{}s;
                                    $body =~ s{</body>\s*</html>\s*$}{};
                                    $n    =~ s{/}{::}g;
                                    $m->print("h1 {$n}");
                                    $m->print( "h2 {"
                                          . _('Schema')
                                          . "}<pre>$schema</pre>" )
                                      if ($schema);
                                    $body =~
s{<a href="http://search\.cpan\.org/perldoc\?(Jifty%3A%3A[^"]+)"([^>]*)>}{<a href="content.html?n=$1"$2>}g;
                                    $body =~ s!}\n\tul { !ul { !;
                                    $body =~ s!}!}}!;
                                    $body =~ s!p { }!!;
                                    $body =~ s!<a name=!<a id=!g;
                                    $body =~ s!__index__!index!g;
                                    $m->print($body);
                                    </%PERL> < /body></ html >
                                      <%ARGS> $Target => '&method=content' $n =>
                                      'Jifty' < /%ARGS>
require File::Basename;
require File::Find;
require File::Temp;
require File::Spec;
require Pod::Simple::HTML;
}

sub __jifty::online_docs::index.html { 
<!DOCTYPE HTML PUBLIC "-/ / W3C // DTD HTML 4.01 Frameset // EN "
" http: // www . w3 . org / TR / html4 /">
<html lang="en">
<head>
<title><%_( $n || 'Jifty') %> - <%_('Online Documentation')%></ title >
                                      <style type="text/css"> <
                                      !--a     { text-decoration: none }
                                      a: hover { text-decoration: underline }
                                      a: focus {
                                        background: #99ff99; border: 1px black dotted }
                                        --> </style> < /head>
<FRAMESET COLS="*, 250">
    <FRAME src="./content . html " name=" podcontent ">
    <FRAME src=" . /toc.html" name="podtoc">
    <NOFRAMES>
        <a style="display: none" href="#toc"><%_('Table of Contents')%></ a >
                                          <& content.html, Target => '' & > h1 {
                                            <a id="toc"> <
                                              %_ ('Table of Contents') % > </a>;
                                          }
                                          <& toc.html, Target => '' & >
                                          </NOFRAMES> < /FRAMESET>
my (
$n => undef
) = get(qw());
}

sub __jifty::online_docs::toc.html { 
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-/ / W3C // DTD XHTML 1.1 // EN "
" http: // www . w3 . org / TR / xhtml11 / DTD / xhtml11 . dtd ">
<html xmlns=" http: // www . w3 . org / 1999 / xhtml " xml:lang=" en " >
<head>
<title><% _($n || 'Jifty') %> - <%_('Jifty Developer Documentation Online')%></title>
<style type=" text / css "><!--
a { text-decoration: none }
a:hover { text-decoration: underline }
a:focus { background: #99ff99; border: 1px black dotted }
--></style>
</head>
<body style=" background:    #dddddd">
                                          <%PERL> my @found;
                                        File::Find::find(
                                            {
                                                untaint => 1,
                                                wanted  => sub {
                                                    return
                                                      unless
                                                      /(\w+)\.(?:pm|pod)$/;
                                                    my $name =
                                                      $File::Find::name;
                                                    $name =~ s/.*lib\b.//;
                                                    $name =~ s!\.(?:pm|pod)!!i;
                                                    $name =~ s!\W!::!g;
                                                    push @found, $name;
                                                },
                                                follow => ( $^O ne 'MSWin32' )
                                            },
                                            Jifty::Util->app_root . "/lib",
                                        );

                                        File::Find::find(
                                            {
                                                untaint => 1,
                                                wanted  => sub {
                                                    return
                                                      unless $File::Find::name
                                                      =~ /^(?:.*?)(Jifty.*?\.(?:pm|pod))$/;
                                                    my $name = $1;
                                                    $name =~ s/.*lib\b.//;
                                                    $name =~ s!\.(?:pm|pod)!!i;
                                                    $name =~ s!\/!::!g;
                                                    push @found, $name;
                                                },
                                                follow => ( $^O ne 'MSWin32' )
                                            },
                                            Jifty::Util->jifty_root,
                                        );

                                        my $indent = 0;
                                        my $prev   = '';
                                        foreach my $file ( sort @found ) {
                                            my ( $parent, $name ) = ( $1, $2 )
                                              if $file =~ /(?:(.*)::)?(\w+)$/;
                                            $parent = '' unless defined $parent;
                                            if ( $file =~ /^$prev\::(.*)/ ) {
                                                my $foo = $1;
                                                while ( $foo =~ s/(\w+)::// ) {
                                                    $indent++;
                                                    $m->print(
                                                        (
                                                            '&nbsp;&nbsp;&nbsp;'
                                                              x $indent
                                                        )
                                                    );
                                                    $m->print("$1<br />");
                                                }
                                                $indent++;
                                            }
                                            elsif ( $prev !~ /^$parent\::/ ) {
                                                $indent = 0
                                                  unless length $parent;
                                                while ( $parent =~ s/(\w+)// ) {
                                                    next if $prev =~ s/\b$1:://;
                                                    while ( $prev =~ s/::// ) {
                                                        $indent--;
                                                    }
                                                    $m->print(
                                                        (
                                                            '&nbsp;&nbsp;&nbsp;'
                                                              x $indent
                                                        )
                                                    );
                                                    $m->print("$1<br />");
                                                    $indent++;
                                                }
                                            }
                                            elsif (
                                                $prev =~ /^$parent\::(.*::)/ )
                                            {
                                                my $foo = $1;
                                                while ( $foo =~ s/::// ) {
                                                    $indent--;
                                                }
                                            }
                                            $m->print(
                                                (
                                                    '&nbsp;&nbsp;&nbsp;' x
                                                      $indent
                                                )
                                                . '<a target="podcontent" href="content.html?n='
                                                  . $file . '">'
                                                  . $name
                                                  . '</a><br />' . "\n"
                                            );
                                            $prev = $file;
                                        }

                                        </%PERL> < /body></ html >
                                          <%INIT> require File::Basename;
                                        require File::Find;
                                        require File::Temp;
                                        require File::Spec;
                                        require Pod::Simple::HTML;
                                        </%INIT> < %ARGS >
                                          $n => '' $method => '' $Target =>
                                          '&method=content' < /%ARGS>
}
                  }

1;
