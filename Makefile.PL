use inc::Module::Install 0.46;
name('Jifty');

# this is a dev version, CPAN.pm will not install by default
requires(perl => '5.8.3');  
requires('Apache::Session');
requires('App::CLI' => 0.03 ); # App::CLI::Command::Help App::CLI::Command
requires('Cache::Cache'); #Cache::FileCache
requires('Calendar::Simple');
requires('Class::Accessor');
requires('Class::Container');
requires('Clone');
requires('Compress::Zlib');
requires('DBD::SQLite');
requires('Data::Page');
requires('Date::Manip');
requires('Digest::MD5');
requires('Email::Folder');
requires('Email::LocalDelivery');
requires('Email::Send' => '1.99_01'); # Email::Send::Jifty::Test
requires('Email::Simple');
requires('Email::Simple::Creator');
requires('Encode');
requires('File::Find::Rule');
requires('File::MMagic');
requires('File::ShareDir');
requires('HTML::Entities');
requires('HTML::Mason' => 1.3101);           # HTML::Mason::Exceptions HTML::Mason::FakeApache HTML::Mason::MethodMaker HTML::Mason::Request HTML::Mason::Utils
requires('HTML::Mason::Plugin');
requires('HTTP::Cookies');
requires('HTTP::Date');
requires('HTTP::Server::Simple' => '0.10');  # HTTP::Server::Simple::CGI
requires('HTTP::Server::Simple::Recorder');
requires('Hash::Merge');
requires('Hook::LexWrap');
requires('Jifty::DBI' => '0.16' );            # Jifty::DBI::Collection Jifty::DBI::Handle Jifty::DBI::Record::Cachable Jifty::DBI::SchemaGenerator
requires('Locale::Maketext::Extract' => '0.11');
requires('Locale::Maketext::Lexicon' => '0.57');
requires('Log::Log4perl');
requires('LWP::UserAgent');
requires('MIME::Types');
requires('Module::CoreList');
requires('Module::Install::Admin' => '0.50');
requires('Module::Pluggable' => '2.95');
requires('Module::Refresh' => '0.09');
requires('Params::Validate');
requires('Pod::Simple'); #Pod::Simple::Text
requires('Scalar::Util');
requires('String::Koremutake');
requires('Test::Base' => 0.44);            # Test::Base::Filter
requires('Test::HTML::Lint');
requires('Test::HTTP::Server::Simple' => 0.02);
requires('Test::More' => 0.62);
requires('Test::Pod::Coverage');
requires('Test::WWW::Mechanize');
requires('Time::HiRes');
requires('UNIVERSAL::require');
requires('URI');
requires('WWW::Mechanize' => 1.12);
requires('XML::Writer');
requires('XML::XPath');
requires('version');

if (can_cc()) {
    # Always require the Syck bindings if a C compiler is available
    requires('YAML::Syck' => 0.41);
    requires('JSON::Syck' => 0.10);
}
else {
    requires('YAML' => 0.35) unless can_use('YAML::Syck' => 0.41);
    requires('JSON' => 0.01) unless can_use('JSON::Syck' => 0.10);
}

version_from('lib/Jifty.pm');
#&auto_bundle_deps();
&auto_install();
#&auto_include_dependent_dists();

install_script('bin/jifty');
install_share;

# Test all of our sub-dist tests too
tests('t/*.t t/*/t/*.t');

&WriteAll;

