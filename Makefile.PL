use inc::Module::Install 0.46;
name('Jifty');
# this is a dev version, CPAN.pm will not install by default
requires(perl => '5.8.3');
requires('Apache::Session');
requires('App::CLI'); # App::CLI::Command
requires('Cache::Cache'); #Cache::FileCache
requires('CGI::Cookie');
requires('CGI');                   # CGI::Fast
requires('Class::Accessor');
requires('Clone');
requires('Cwd');
requires('Data::JavaScript::Anon');
requires('Data::Page');
requires('Digest::MD5');
requires('DBD::SQLite');
requires('Email::Folder');
requires('Email::LocalDelivery');
requires('Email::Send' => '1.99_01');
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
requires('Jifty::DBI' => '0.06' );            # Jifty::DBI::Collection Jifty::DBI::Handle Jifty::DBI::Record::Cachable Jifty::DBI::SchemaGenerator
requires('JSON');
requires('Log::Log4perl');
requires('Locale::Maketext::Simple');
requires('Math::BigInt');
requires('Module::Pluggable' => '2.95');
requires('Module::Refresh');
requires('Pod::Usage');
requires('Pod::Simple::Text');
requires('Scalar::Util');
requires('String::Koremutake');
requires('Test::Base');            # Test::Base::Filter
requires('Test::More');
requires('Test::HTML::Lint');
requires('Test::HTTP::Server::Simple' => 0.02);
requires('Test::WWW::Mechanize');
requires('Time::ParseDate');
requires('UNIVERSAL::require');
requires('URI');
requires('WWW::Mechanize' => 1.12);
requires('version');
requires('XML::Writer');
requires('XML::XPath');
requires('YAML');
version('0.'.time());
#&auto_bundle_deps();
&auto_install();

install_script('bin/jifty');
install_share;

# Test all of our sub-dist tests too
tests('t/*.t t/*/t/*.t');

&WriteAll;

