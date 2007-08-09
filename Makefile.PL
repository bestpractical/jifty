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
requires('Class::Trigger');
requires('CGI' => '3.19');
requires('CGI::Cookie::Splitter');
requires('Crypt::CBC');
requires('Crypt::Rijndael');
requires('Compress::Zlib');
requires('CSS::Squish' => 0.05 );
requires('DBD::SQLite' => 1.11 );
requires('Data::Page');
requires('Data::UUID');
requires('DateTime');
requires('Date::Manip');
requires('Email::Folder');
requires('Email::LocalDelivery');
requires('Email::MIME');
requires('Email::MIME::Creator');
requires('Email::MIME::ContentType');
requires('Email::MIME::CreateHTML');
requires('Email::MIME::Modifier');
requires('Email::Send' => '1.99_01'); # Email::Send::Jifty::Test
requires('Email::Simple');
requires('Email::Simple::Creator');
requires('Exporter::Lite');
requires('File::Find::Rule');
requires('File::MMagic');
requires('File::ShareDir' => '0.04');
requires('HTML::Entities');
requires('HTML::Lint');
requires('HTML::Mason' => 1.3101);           # HTML::Mason::Exceptions HTML::Mason::FakeApache HTML::Mason::MethodMaker HTML::Mason::Request HTML::Mason::Utils
requires('HTML::Mason::Plugin');
requires('HTTP::Cookies');
requires('HTTP::Date');
requires('HTTP::Server::Simple' => '0.26');  # HTTP::Server::Simple::CGI
requires('HTTP::Server::Simple::Recorder');
requires('Hash::Merge');
requires('Hook::LexWrap');
requires('IPC::PubSub' => '0.23' );
requires('IPC::Run3');
requires('Jifty::DBI' => '0.42' );            # Jifty::DBI::Collection Jifty::DBI::Handle Jifty::DBI::Record::Cachable Jifty::DBI::SchemaGenerator
requires('Locale::Maketext::Extract' => '0.20');
requires('Locale::Maketext::Lexicon' => '0.60');
requires('Log::Log4perl' => '1.04');
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
requires('Scalar::Defer' => '0.10');
requires('Shell::Command');
requires('String::Koremutake');
requires('SQL::ReservedWords');
requires('SVN::Fs');
requires('SVN::Repos');
requires('SVN::Simple::Edit');
requires('Template::Declare' => '0.07');                # Template::Declare::Tags
requires('Template::Declare' => '0.21');                # Template::Declare::Tags
requires('Test::Base');
requires('Test::LongString');
requires('Test::Log4perl');
requires('Test::More' => 0.62 ),
requires('Test::Pod::Coverage'),
requires('Test::WWW::Mechanize' => 1.04 ),
requires('WWW::Mechanize' => 1.12 ),
requires('UNIVERSAL::require');
requires('URI');
requires('XML::Writer' => '0.601');
requires('XML::Simple');
requires('XML::XPath');
requires('version');

if (can_cc()) {
    # Always require the Syck bindings if a C compiler is available
    requires('YAML::Syck' => 0.82);
    requires('YAML' => 0.35); 	# Use YAML::Dump for the moment since YAML.pm segfaults on
				# reading stupidly long (~20K characters) double-quoted
				# strings, and we need to produce YAML.pm-readable output.
    requires('JSON::Syck' => 0.15);
}
else {
    requires('YAML' => 0.60) unless can_use('YAML::Syck' => 0.82);
    requires('JSON' => 0.01) unless can_use('JSON::Syck' => 0.15);
}

features(
    'Administrative Interface (web)' => [ 
        -default => 1,
       requires( 'Pod::Simple') # Pod::Simple::Text Pod::Simple::HTML
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
        recommends('Module::Refresh' => '0.09')
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
    'Chart Plugin (none of these must be installed for Charts to work)' => [
        -default => 0,
        recommends('Chart::Base'),
        recommends('GD'),          # for a testing hack
        recommends('GD::Graph'),
        recommends('XML::Simple'),
        recommends('Image::Info'), # for testing
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

# Test all of our sub-dist tests too
tests('t/*.t t/*/t/*.t');

WriteAll;

