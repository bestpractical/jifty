use inc::Module::Install;
name('Jifty');
# this is a dev version, CPAN.pm will not install by default
requires('Apache::Session');
requires('App::CLI');
requires('CGI::Cookie');
requires('CGI');                   # CGI::Fast
requires('Class::Accessor');
requires('Clone');
requires('Cwd');
requires('Data::Page');
requires('Data::UUID');
requires('DBD::Pg');
requires('Email::Send' => '1.99_01');
requires('Email::Simple');
requires('Email::Simple::Creator');
requires('Exporter');
requires('File::Basename');
requires('File::Find');
requires('File::Spec');
requires('FindBin');
requires('Getopt::Long');
requires('HTML::Entities');
requires('HTML::Mason' => 1.3101);           # HTML::Mason::CGIHandler HTML::Mason::Interp HTML::Mason::Plugin
requires('HTML::Mason::Plugin');
requires('HTTP::Cookies');
requires('HTTP::Server::Simple' => '0.10');
requires('HTTP::Server::Simple::Mason');
requires('HTTP::Server::Simple::Recorder');
requires('Hash::Merge');
requires('Hook::LexWrap');
requires('Jifty::DBI');            # Jifty::DBI::Collection Jifty::DBI::Handle Jifty::DBI::Record::Cachable Jifty::DBI::SchemaGenerator
requires('Log::Log4perl');
requires('Module::Pluggable' => '2.95');
requires('Module::Refresh');
requires('Pod::Usage');
requires('Scalar::Util');
requires('Test::Base');            # Test::Base::Filter
requires('Test::More');
requires('Test::HTML::Lint');
requires('Test::HTTP::Server::Simple' => 0.02);
requires('Test::WWW::Mechanize');
requires('Time::ParseDate');
requires('UNIVERSAL::require');
requires('URI');
requires('WWW::Mechanize' => 1.12);
requires('XML::XPath');
requires('YAML');
version('0.'.time());
&auto_install;
&WriteAll;
