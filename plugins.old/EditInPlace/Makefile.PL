use inc::Module::Install 0.46;
name('Jifty-Plugin-EditInPlace');
requires('Jifty' => '0.60510' );
&auto_install();

install_share;

WriteAll;

