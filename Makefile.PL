use inc::Module::Install 0.46;
name('Jifty');

# this is a dev version, CPAN.pm will not install by default
requires(perl => '5.8.3'); 
requires('Apache::Session');
requires('App::CLI' => 0.03 ); # App::CLI::Command::Help App::CLI::Command
requires('CGI');                   # CGI::Fast
requires('CGI::Cookie');
requires('Cache::Cache'); #Cache::FileCache
requires('Carp');
requires('Class::Accessor');
requires('Clone');
requires('Cwd');
requires('DBD::SQLite');
requires('Data::Page');
requires('Digest::MD5');
requires('Email::Folder');
requires('Email::LocalDelivery');
requires('Email::Send' => '1.99_01'); # Email::Send::Jifty::Test
requires('Email::Simple');
requires('Email::Simple::Creator');
requires('Exporter');
requires('File::Basename');
requires('File::Copy');
requires('File::Find');
requires('File::ShareDir');
requires('File::Spec');
requires('FindBin');
requires('Getopt::Long');
requires('HTML::Entities');
requires('HTML::Mason' => 1.3101);           # HTML::Mason::CGIHandler HTML::Mason::Interp HTML::Mason::Plugin
requires('HTML::Mason::Plugin');
requires('HTTP::Cookies');
requires('HTTP::Server::Simple' => '0.10');
requires('HTTP::Server::Simple::Mason' => '0.09');
requires('HTTP::Server::Simple::Recorder');
requires('Hash::Merge');
requires('Hook::LexWrap');
requires('JSON');
requires('Jifty::DBI' => '0.06' );            # Jifty::DBI::Collection Jifty::DBI::Handle Jifty::DBI::Record::Cachable Jifty::DBI::SchemaGenerator
requires('Locale::Maketext::Simple');
requires('Log::Log4perl');
requires('Math::BigInt');
requires('Module::Install' => '0.50');
requires('Module::Pluggable' => '2.95');
requires('Module::Refresh');
requires('Pod::Simple::Text');
requires('Pod::Usage');
requires('Scalar::Util');
requires('String::Koremutake');
requires('Test::Base');            # Test::Base::Filter
requires('Test::HTML::Lint');
requires('Test::HTTP::Server::Simple' => 0.02);
requires('Test::More' => 0.62);
requires('Test::Pod::Coverage');
requires('Test::WWW::Mechanize');
requires('Time::HiRes');
requires('Time::ParseDate');
requires('UNIVERSAL::require');
requires('UNIVERSAL');
requires('URI');
requires('WWW::Mechanize' => 1.12);
requires('XML::Writer');
requires('XML::XPath');
requires('version');
requires('YAML');
version_from('lib/Jifty.pm');
#&auto_bundle_deps();
&auto_install();

install_script('bin/jifty');
install_share;

# Test all of our sub-dist tests too
tests('t/*.t t/*/t/*.t');

&WriteAll;

