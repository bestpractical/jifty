package Jifty::Script::App;
use base 'Jifty::Script::Command';

use YAML;



sub options {
        ($_[0]->SUPER::options,
            'n|name=s' => 'name',
        )

        }


sub run {
    my $self = shift;

    my $prefix = $self->{name} ||''; 

    unless ($prefix =~ /\w+/ ) { die "You need to give your new Jifty app a --name"."\n";}

    my $modname = $self->{modname} || ucfirst($prefix);

    $self->status("Creating new application ".$self->{name});
    mkdir($prefix);

    foreach my $dir ($self->directories) {
        my $path = $prefix."/". $dir;
        $path =~ s/__APP__/$modname/;
        $self->status("Creating directory $dir");
        mkdir( $path);

    }

    $self->create_default_config();
    
    foreach my $script ($self->scripts) {
        my $file;
        open (my $file, "$path/$script");

    }

}


sub scripts {
    return qw(
        bin/jfmi
        bin/standalone_httpd
        bin/handler.fcgi
        bin/schema
    );

}


sub directories {
return qw(


    bin
    etc
    doc
    log
    web
    web/templates
    web/static
    email/templates
    lib
    lib/__APP__
    lib/__APP__/Model
    lib/__APP__/Action
    lib/__APP__/Notification
    

);



}


sub create_default_config {
    my $self = shift;

my $config = YAML::Load( qq!
---
framework:
  ApplicationClass: @{[$self->{'name'}]}
  ActionBasePath: @{[$self->{'name'}]}::Action
  LogConfig: etc/log4perl.conf
  Web:
    Port: 8008
    TemplateRoot: html
    StaticRoot: static
    BaseURL: http://localhost
  Database:
    Database: @{[lc $self->{'name'}]}
    Driver: Pg
    Host: localhost
    User: postgres
    Version: 0.0.1
    Password: ''
    RequireSSL: 0
  Mailer: IO
  MailerArgs:
    - %log/mail.log%
  SiteConfig: etc/site_config.yml
application: 
  MaxWurbles: 9
!);
YAML::DumpFile($self->{'name'} ."/etc/config.yml", $config);
}


1;

