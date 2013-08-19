use inc::Module::Install 0.46;
name('Jifty');
license('Perl');
perl_version '5.8.3';
requires('Any::Moose');
requires('App::CLI' => 0.08 ); # App::CLI::Command::Help App::CLI::Command
requires('Cache::Cache'); #Cache::FileCache
requires('Calendar::Simple');
requires('Carp::Clan');
requires('Class::Accessor'); # Class::Accessor::Fast
requires('Class::Container');
requires('Class::Data::Inheritable');
requires('Class::Trigger' => '0.13');
requires('Clone' => '0.27');
requires('CGI' => '3.30');
requires('CGI::Emulate::PSGI' => 0.06);
requires('Class::Inspector' => 1.20); # For File::ShareDir on Win32
requires('Crypt::CBC');
requires('Crypt::Rijndael');
requires('Compress::Zlib');
requires('CSS::Squish' => 0.07 );
requires('DBI');
requires('DBD::SQLite' => 1.11 );
requires('Data::Page');
requires('Data::UUID');
requires('DateTime');
requires('DateTime::Locale');
requires('Date::Manip' => '6.01');
requires('Email::Folder');
requires('Email::LocalDelivery' => 0.217 );
requires('Email::MIME' => 1.900 );
requires('Email::MIME::ContentType' => 1.012 );
requires('Email::MIME::CreateHTML');
requires('Email::Send' => '2.10');
requires('Email::Simple' => 2.003);
requires('Email::Simple::Creator' => 1.400 );
requires('Exception::Class');
requires('Exporter::Lite');
requires('File::Find::Rule');
requires('File::MMagic');
requires('File::ShareDir' => '1.00');
requires('File::Spec' => '3.14');
requires('File::Temp' => '0.15'); # we need cleanup()
requires('HTML::Entities');
requires('HTML::Lint');
requires('HTML::Mason' => 1.3101);           # HTML::Mason::Exceptions HTML::Mason::FakeApache HTML::Mason::MethodMaker HTML::Mason::Request HTML::Mason::Utils
requires('HTML::Mason::Plugin');
requires('HTML::TreeBuilder::XPath');
requires('HTTP::Cookies');
requires('HTTP::Date');
requires('Hash::Merge', '0.12');
requires('Hash::MultiValue', 0.05);
requires('IO::Handle::Util');
requires('IPC::Run3');
requires('Jifty::DBI' => '0.68' );            # Jifty::DBI::Collection Jifty::DBI::Handle Jifty::DBI::Record::Cachable Jifty::DBI::SchemaGenerator
requires('JSON' => 2.17);
requires('List::MoreUtils');
requires('Locale::Maketext::Extract' => '0.35');
requires('Locale::Maketext::Lexicon' => '0.77');
requires('Log::Log4perl' => '1.11'); # Log::Log4perl::Appender Log::Log4perl::Level
requires('LWP::UserAgent'); # Net::HTTP LWP::Simple HTTP::Request HTTP::Request::Common
requires('MIME::Types');
requires('Module::Pluggable' => '3.7'); # Module::Pluggable::Object
requires('Module::Pluggable::Object');
requires('Module::CoreList');
requires('Module::Refresh');
requires('Module::ScanDeps');
requires('Object::Declare' => '0.13');
requires('Params::Validate');
requires('Plack' => '0.9940'); # Plack::Loader Plack::Test Plack::Util Plack::Builder Plack::Request Plack::Handler::FCGI HTTP::Message::PSGI Plack::Response
requires('Plack::Middleware::Deflater');
requires('Scalar::Defer' => '0.12');
requires('Shell::Command');
requires('String::BufferStack' => '1.12');
requires('String::Koremutake');
requires('SUPER');
requires('SQL::ReservedWords');
requires('Template::Declare' => '0.36');                # Template::Declare::Tags
requires('Test::Base');
requires('Test::Exception');
requires('Test::LongString');
requires('Test::More' => 0.62 );
requires('Test::Script::Run' => 0.03);
requires('Test::WWW::Mechanize' => 1.04 );
requires('Test::WWW::Mechanize::PSGI' => 0.35 );
requires('Test::WWW::Selenium' => 1.18 );
requires('WWW::Mechanize' => 1.51 );
requires('UNIVERSAL::require');
requires('URI' => 1.31);
requires('URI::Escape');
requires('XML::Writer' => '0.601');
requires('XML::Simple');
requires('version');

if (can_cc()) {
    # Always require the Syck bindings if a C compiler is available
    requires('YAML::Syck' => 0.71);
    requires('YAML' => 0.35); 	# Use YAML::Dump for the moment since YAML.pm segfaults on
				# reading stupidly long (~20K characters) double-quoted
				# strings, and we need to produce YAML.pm-readable output.
    requires('JSON::XS' => 2.27);
}
else {
    requires('YAML' => 0.35) unless can_use('YAML::Syck' => 0.71);
}

feature "FastCGI support" =>
    -default => 0,
    recommends('FCGI::ProcManager' => 0.19),
    ;

feature "Memcached support for serving compressed CSS and JS from Jifty's CAS" =>
    -default => 1,
    recommends('Cache::Memcached' => 1.25),
    ;

feature "Event-based publish/subscribe framework" =>
    -default => 0,
    recommends('Web::Hippie'), # AnyMQ Web::Hippie::App::JSFiles
    ;

feature "Client-side session cookies (untested)" =>
    -default => 0,
    recommends("CGI::Cookie::Splitter");

feature "RPC support using AMQP" =>
    -default => 0,
    recommends('Web::Hippie'), # AnyMQ Web::Hippie::App::JSFiles
    recommends('AnyEvent::RabbitMQ::RPC'),
    ;

feature 'Administrative Interface (web)' =>
    -default => 1,
    recommends('Pod::Simple' => 0), # Pod::Simple::Text Pod::Simple::HTML
    ;

feature 'Development of a jifty application' =>
    -default => 1,
    recommends('DBD::SQLite' => 1.11),
    recommends('Test::Base' => 0.44),            # Test::Base::Filter
    recommends('Module::Install::Admin' => '0.50'),
    recommends('Test::HTML::Lint' => 0),
    recommends('Test::MockModule' => '0.05'),
    recommends('Test::MockObject' => '1.07'),
    recommends('Module::Refresh' => '0.09'),
    # Sub::Exporter is already required by SQL::ReservedWords (and also by
    # Moose if that's around), but make it explicit
    recommends('Sub::Exporter'),
    recommends('Test::Email' => 0),
    recommends('Email::Abstract' => 0),
    ;

feature 'Development of the jifty framework' =>
    -default => 0,
    recommends('DBD::SQLite' => 0),
    recommends('Class::Accessor::Named' => 0),
    recommends('Devel::Cover' => 0),
    recommends('Module::CoreList' => 0),
    recommends('Module::Install::Admin' => '0.50'),
    ;

feature 'Improved halos' =>
    -default => 0,
    recommends('Data::Dump::Streamer' => 0),
    ;


no_index( directory => qw< debian doc examples share > );
no_index package => 'DB';

version_from('lib/Jifty.pm');
&auto_install();

install_script('bin/jifty');
install_share;

# Test all of our sub-dist tests too
tests('t/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t');

WriteAll;

