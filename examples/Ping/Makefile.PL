use inc::Module::Install;
name('Ping');
version('0.01');
requires('Jifty' => '0.61025');
requires('Net::Server' => 0);

WriteAll;
