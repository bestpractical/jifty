use inc::Module::Install 0.46;
name('Comment');
version_from('../../lib/Jifty.pm');

requires('HTML::Scrubber'),
requires('MIME::Base64::URLSafe'),
requires('Net::Akismet'),
requires('Regexp::Common'),
requires('Regexp::Common::Email::Address'),

&auto_install();

WriteAll;
