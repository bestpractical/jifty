use inc::Module::Install 0.46;
name('Jifty');
license('Perl');
requires(perl => '5.8.3');
requires('App::CLI' => 0.03 ); # App::CLI::Command::Help App::CLI::Command
requires('Cache::Cache'); #Cache::FileCache
requires('Calendar::Simple');
requires('Class::Accessor'); # Class::Accessor::Fast
requires('Class::Container');
requires('Class::Data::Inheritable');
requires('Class::Trigger' => '0.12');
requires('Clone' => '0.27');
requires('CGI' => '3.30');
requires('CGI::Cookie::Splitter');
requires('Class::Inspector' => 1.20); # For File::ShareDir on Win32
requires('Crypt::CBC');
requires('Crypt::Rijndael');
requires('Compress::Zlib');
requires('CSS::Squish' => 0.07 );
requires('DBD::SQLite' => 1.11 );
requires('Data::Page');
requires('Data::UUID');
requires('DateTime');
requires('DateTime::Locale');
requires('Date::Manip');
requires('Email::Folder');
requires('Email::LocalDelivery' => 0.217 );
requires('Email::MIME' => 1.861);
requires('Email::MIME::Creator' => 1.450 );
requires('Email::MIME::ContentType' => 1.012 );
requires('Email::MIME::CreateHTML');
requires('Email::MIME::Modifier' => 1.442 );
requires('Email::Send' => '2.0'); # Email::Send::Jifty::Test
requires('Email::Simple' => 2.003);
requires('Email::Simple::Creator' => 1.400 );
requires('Exporter::Lite');
requires('File::Find::Rule');
requires('File::MMagic');
requires('File::ShareDir' => '0.04');
requires('File::Spec' => '3.14');
requires('File::Temp' => '0.15'); # we need cleanup()
requires('HTML::Entities');
requires('HTML::Lint');
requires('HTML::Mason' => 1.3101);           # HTML::Mason::Exceptions HTML::Mason::FakeApache HTML::Mason::MethodMaker HTML::Mason::Request HTML::Mason::Utils
requires('HTML::Mason::Plugin');
requires('HTTP::Cookies');
requires('HTTP::Date');
requires('HTTP::Server::Simple' => '0.28');  # HTTP::Server::Simple::CGI
requires('HTTP::Server::Simple::Recorder');
requires('Hash::Merge');
requires('Hook::LexWrap');
requires('IPC::PubSub' => '0.23' );
requires('IPC::Run3');
requires('Jifty::DBI' => '0.49' );            # Jifty::DBI::Collection Jifty::DBI::Handle Jifty::DBI::Record::Cachable Jifty::DBI::SchemaGenerator
requires('List::MoreUtils');
requires('Locale::Maketext::Extract' => '0.20');
requires('Locale::Maketext::Lexicon' => '0.60');
requires('Log::Log4perl' => '1.04'); # Log::Log4perl::Appender
requires('LWP::UserAgent'); # Net::HTTP
requires('MIME::Types');
requires('Module::Pluggable' => '3.5'); # Module::Pluggable::Object
requires('Module::Pluggable::Object');
requires('Module::CoreList');
requires('Module::Refresh');
requires('Module::ScanDeps');
requires('Object::Declare' => '0.13');
requires('PadWalker');
requires('Params::Validate');
requires('Scalar::Defer' => '0.12');
requires('Shell::Command');
requires('String::Koremutake');
requires('SQL::ReservedWords');
requires('Template::Declare' => '0.26');                # Template::Declare::Tags
requires('Test::Base');
requires('Test::Log4perl');
requires('Test::LongString');
requires('Test::More' => 0.62 ),
requires('Test::Pod::Coverage'),
requires('Test::WWW::Mechanize' => 1.04 ),
requires('Test::WWW::Selenium'),
requires('WWW::Mechanize' => 1.30 ),
requires('UNIVERSAL::require');
requires('URI' => 1.31);
requires('URI::Escape');
requires('XML::Writer' => '0.601');
requires('XML::Simple');
requires('XML::XPath');
requires('version');

if (can_cc()) {
    # Always require the Syck bindings if a C compiler is available
    requires('YAML::Syck' => 0.71);
    requires('YAML' => 0.35); 	# Use YAML::Dump for the moment since YAML.pm segfaults on
				# reading stupidly long (~20K characters) double-quoted
				# strings, and we need to produce YAML.pm-readable output.
    requires('JSON::Syck' => 0.29);
}
else {
    requires('YAML' => 0.35) unless can_use('YAML::Syck' => 0.71);
    requires('JSON' => 0.01) unless can_use('JSON::Syck' => 0.29);
}

features(
    'Administrative Interface (web)' => [ 
        -default => 1,
       recommends( 'Pod::Simple') # Pod::Simple::Text Pod::Simple::HTML
    ],
    'Development of a jifty application' => [
        -default => 1,
        recommends('DBD::SQLite' => 1.11 ),
        recommends('Test::Base' => 0.44 ),            # Test::Base::Filter
        recommends('Module::Install::Admin' => '0.50'),
        ($^O ne 'MSWin32' ? recommends('Test::HTTP::Server::Simple' => '0.02' ) : ()),
        recommends('Test::HTML::Lint'),
        recommends('Test::MockModule' => '0.05'),
        recommends('Test::MockObject' => '1.07'),
        recommends('Module::Refresh' => '0.09'),
        recommends('Test::WWW::Declare' => '0.01'),
    ],
    'Development of the jifty framework' => [
        -default => 0,
        recommends('DBD::SQLite'),
        recommends('Class::Accessor::Named'),
        recommends('Devel::Cover'),
        recommends('Module::CoreList'),
        recommends('Module::Install::Admin' => '0.50')
     ],
    'Forking jifty server' => [
        -default => 0,
        recommends('Net::Server::Fork'),
    ],
    'Pre-forking jifty server' => [
        -default => 0,
        recommends('Net::Server::PreFork'),
    ],
    'Apache2/ModPerl2 handler' => [
        -default => 0,
        recommends('Apache2::Const'),
    ],
    'Experimental features' => [
        -default => 0,
        recommends('PAR::Dist::FromCPAN'),
    ],
    'OpenID Login Plugin' => [
        -default => 0,
        recommends('Net::OpenID::Consumer'),
        recommends('Cache::FileCache'),
        recommends('LWPx::ParanoidAgent'),
    ],
    'Facebook Login Plugin' => [
        -default => 0,
        recommends('WWW::Facebook::API' => '0.3.6'),
    ],
    'Jifty console' => [
        -default => 0,
        recommends('Devel::EvalContext'),
    ],
    'Jifty REPL' => [
        -default => 0,
        recommends('Devel::REPL'), # Devel::REPL::Script
    ],
    'Chart Plugin (none of these need to be installed for Charts to work)' => [
        -default => 0,
        recommends('Chart::Base'),
        recommends('GD'),          # for a testing hack
        recommends('GD::Graph'),
        recommends('XML::Simple'),
        recommends('Image::Info'), # for testing
    ],
    'Memory Leak Plugins' => [
        -default => 0,
        recommends('Devel::Events::Objects' => '0.02'), # Devel::Events::Handler::ObjectTracker Devel::Events::Generator::Objects
        recommends('Devel::Size'),
        recommends('Devel::Gladiator'),
        recommends('Proc::ProcessTable'),
    ],
    'Improved halos' => [
        -default => 0,
        recommends('Template::Declare' => '0.28'),
        recommends('Data::Dump::Streamer'),
    ],
);


no_index( directory => qw< debian doc examples share plugins/*/t> );
no_index package => 'DB';

version_from('lib/Jifty.pm');
#&auto_bundle_deps();
&auto_install();
#&auto_include_dependent_dists();

install_script('bin/jifty');
install_share;

# INSTALLDIRS need to be set before Makefile if you want to change default install path
# debian packaging use :
#  INSTALLDIRS=vendor $(PERL) Makefile.PL --skipdeps INSTALLDIRS=vendor 
#
# TODO?: JIFTY_PLUGINS=ALL
# ls plugins -> Authentication-CAS Authentication-Ldap  Multipage  TabView
my @plugins = defined $ENV{JIFTY_PLUGINS} ? split(/ /, $ENV{JIFTY_PLUGINS}) : qw(TabView);

# Test all of our sub-dist tests too
tests(join(' ', qw(t/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t), map { "plugins/$_/t/*.t"} @plugins));


for (@plugins) {
    die unless -d "plugins/$_";
#    install_share("plugins/$_/share");
    chdir("plugins/$_");
    system("$^X -I../../lib Makefile.PL INSTALLDIRS=".$ENV{INSTALLDIRS});
    chdir('../..');

}

postamble(<<"END");

install ::
@{[ join("\n", map { "\tcd plugins/$_;".' $(MAKE) install DESTDIR=$(DESTDIR) PREFIX=$(PREFIX)' } @plugins)   ]}

distclean :: realclean
@{[ "\t".'$(NOECHO) $(NOOP)']}

realclean :: 
@{[ join("\n", map { "\tcd plugins/$_;".' $(MAKE) realclean' } @plugins)   ]}

END

WriteAll;

