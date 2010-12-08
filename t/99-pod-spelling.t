#!/usr/bin/env perl -w

use strict;
use Test::More;
eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD spelling" if $@;
plan skip_all => "Coverage tests only run for authors" unless (-d 'inc/.author');

add_stopwords(<DATA>);

local $ENV{LC_ALL} = 'C';
set_spell_cmd('aspell list -l en');

# monkeypatch Test::Spelling to hide translated files [rt.cpan.org #63755] {{{
my @translations = (
    qr/_de\.pod$/,
    qr/_ja\.pod$/,
    qr/_zhtw\.pod$/,
);

no warnings 'redefine';
no warnings 'once';
my $orig = Test::Spelling->can('pod_file_spelling_ok');
*Test::Spelling::pod_file_spelling_ok = sub {
    my $file = shift;

    if (grep { $file =~ $_ } @translations) {
        return ok("ignoring translated file $file");
    }

    $orig->($file, @_);
};
# }}}

all_pod_files_spelling_ok();

__DATA__
Jifty
LLC
Javascript
login
mixin
mixins
json
Jifty's
subdirectories
webserver
yml
javascript
mimetype
po
podir
FastCGI
Glasser
Vandiver
PARAMHASH
api
autocomplete
jifty
paramhash
plugins
startup
init
pre
Autocompletion
Canonicalization
Canonicalizes
ajax
autocompleted
autocompleter
autocompleters
autocompletion
canoncalizes
canonicalization
canonicalized
canonicalizer
canonicalizers
canonicalizes
checkbox
checkboxes
metadata
unsetting
validator
validators
namespace
whitelist
ACTIONNAME
CAS
filename
memcached
ClassLoader
ClassLoaders
classloader
plugin's
ARGUMENTNAMES
argumentnames
refactored
uri
webservice
webservices
ApplicationClass
ApplicationName
BestPractical
ConfigVersion
MailerArgs
Rebless
Reblessing
VendorConfig
Wifty
YAML
wiki
blogging
changelog
CurrentUser
ACL
request's
DateTime
CURRENTUSER
username
DateTime's
UTC
datetime
natively
HTTPS
PSGI
RULESET
Neo
SSL
streamy
METAEXPRESSION
metaexpression
wildcard
wildcards
subrules
subcondition
pubsub
SQLite
UTF
DevelMode
iso
latin
undecoded
ClassName
backend
LetMe
checksum
letme
LogConfig
LogLevel
del
JDBI
CGI
FIELDNAME
TODO
env
referer
url
webform's
SQL
SomePlugin
reblessed
multipart
multi
runtime
LogReload
Postgres
STDERR
Ruslan
Zakirov
dhandler
autohandler
blog
combobox
signup
AccessControl
JS
UUID
superset
dev
namespaces
timestamp
Automagic
CSS
plack
subrequest
tuple
REQ
ur-time
ConfirmEmail
logout
ActorMetadata
bootstrapper
bootstrappers
onclick
inline
folksonomy
subdirectory
weblog
jquery
jQuery
PrototypeJS
Prototypism
jQueryMigrationGuide
jQuery's
PostgreSQL
PNG
IMG
LDAP
HTC
Turnbull
Lighttpd
ModelColor
cssQuery
GPL
Handlino
SVK
html
apache
myapp
AdminMode
BaseURL
CPAN
ServeStaticFiles
www
BLOBs
checkmark
comboboxes
unrendered
classname
abortable
database's
Nagle's
Changelogger
Hiveminder's
Preloading
UI
jGrowl
JavaScript
workflow
preload
preloadable
preloading
preloads
APIs
CSSQuery
recursing
autocompletions
appender
back-compat
POSTed
REQUESTACTION
jsonToObj
objToJson
DumpFile
LoadFile
lookup
subclause
mouse-overed
refactor
BNF
architected
app's
RDBMS
DBI
ORM
keybindings
RPC
arg
js
Versioning
datastore
roadmap
webforms
unadventureously
PageRegions
chunked
overriden
onclick's
AJAXified
Online
RSS
online
stylesheets
MyWeblog
Weblogs
downlevel
Scriptaculous
stacktrace
RESTful
Plack's
RequestID
RequestInspector
suckish
localizable
MaxRequests
maxrequests
hashrefs
param
ConfigFileVersion
arounding
TABLEs
CheckSchema
BASECLASS
UPGRADECLASS
HOSTNAME
middleware
minifier
psgi
deflater
versioned
devel
jsmin
appenders
ajaxautocompletes
ajaxcanonicalization
ajaxvalidation
submenu
toplevel
AdminUI
OnlineDocs
dropdown
dropdowns
beforehash
submenus
ajaxy
menubar
SetupWizard
lighttpd
refactoring
SkeletonApp
SinglePage
COLUMNNAME
SQLQueries
redispatching
CreateModel
MODELCLASS
DeleteModel
tooltip
internationalizations
lang
tooltips
keybinding
lightbox
onblur
onchange
ondblclick
onfocus
onkeydown
onkeypress
onkeyup
onload
onmousedown
onmousemove
onmouseout
onmouseover
onmouseup
onreset
onselect
onsubmit
onunload
popout
beforeclick
javascript's
STDOUT
dhandlers
SCALARREF
webpage
subcomponent
subcomponents
doctype
prepends
TEMPLATENAME
VIEWCLASS
canonicalizeaction
clkao
IP
XHTML
DATASTRUCTURE
UpdateModel
YUI
CONTID
Masonland
rc
subclassable
cacheable
beforeshow
paramhash's
Refactorings
Fh
upload's
dir
dbiprof
sigready
ok
validationaction
pushfrag

