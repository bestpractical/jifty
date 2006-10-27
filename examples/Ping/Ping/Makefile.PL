use inc::Module::Install;
name('Ping');
version('0.01');
requires('Jifty' => '0.60912');
requires('IPC::PubSub' => '0.11');
requires('Net::Server' => 0);

WriteAll;
