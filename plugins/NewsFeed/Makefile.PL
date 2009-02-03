use inc::Module::Install 0.46;
name('Jifty-Plugin-NewsFeed');
version_from('lib/Jifty/Plugin/NewsFeed.pm');
requires ( 'URI'        => 1.31 );
requires ( 'App::Cache' => 0 );
requires ( 'XML::Feed'  => 0 );
requires ( 'Encode'     => 0 );
&auto_install();
WriteAll;
