use inc::Module::Install;
name('Blog');
version('0.01');
requires('Jifty' => '0.60507');
requires('Regexp::Common::profanity_us' => '0'); 
WriteAll;
