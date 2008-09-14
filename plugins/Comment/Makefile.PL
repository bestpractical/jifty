use inc::Module::Install 0.46;
name('Jifty-Plugin-Comment');
version_from('../../lib/Jifty.pm');

requires('HTML::Scrubber'),
requires('MIME::Base64::URLSafe'),
recommends('Net::Akismet'),
requires('Regexp::Common'),
requires('Regexp::Common::Email::Address'),

&auto_install();

WriteAll;
