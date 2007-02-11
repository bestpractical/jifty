
=head1 NAME

Jifty::Manual::Config


=head1 CONTENT

THIS IS NOTES SO THAT SOMEONE CAN TURN THEM INTO A REAL MANUAL CHAPTER


Jifty has four stages of configuration:


* internal default config

* app configuration

* vendor configuration

* site configuration.


All four are merged together. Your configuration overrides the vendor's configuration which overrides the app configuration which overrides the internal defaults.

When you create an application, jifty writes out the standard default to C<etc/config.yml>.


The configuration is split into two sections

=head2 Framework

There are some toplevel configuration directives at the framework level and some sections:


=head3 Configuration directives


            AdminMode        => 1,
            DevelMode        => 1,
            ApplicationClass => $app_class,
            ApplicationName  => $app_name,
            ApplicationUUID  => $app_uuid,
            LogLevel         => 'INFO',

            Mailer     => 'Sendmail',
            MailerArgs => [],
            L10N       => {
                PoDir => "share/po",
            },
            Plugins    => [],

=head3 Sections

=head4 PubSub

            PubSub           => {
                Enable => undef,
                Backend => 'Memcached',
                    },

=head4 Database

=over

=item                Database =>  $db_name,

=item                Driver   => "SQLite",

SQLite, Pg, mysql, Oracle. These correspond to DBI driver names


=item                Host     => "localhost",

=item                Password => "",

=item                User     => "",

=item                Version  => "0.0.1",

=item                RecordUUIDs => 'active',

The three options are: C<active>, C<lazy>, C<off>

In C<active> mode, Jifty will record a uuid for any record as it's inserted
into the database.  In C<lazy> mode, Jifty will only create a UUID for a row the first time you ask for it. In "off" mode, Jifty will never generate UUIDs for records and asking for one will always return C<undef>. If you don't intend to use UUIDs, the C<lazy> setting is recommended, as certain jifty admin tools can make use of UUIDs.
 


=item                RecordBaseClass => 'Jifty::DBI::Record::Cachable',

=item                CheckSchema => '1'

=back

=head4 Web

            Web        => {
                Port => '8888',
                BaseURL => 'http://localhost',
                DataDir     => "var/mason",
                StaticRoot   => "share/web/static",
                TemplateRoot => "share/web/templates",
                ServeStaticFiles => 1,
                MasonConfig => {
                    autoflush    => 0,
                    error_mode   => 'fatal',
                    error_format => 'text',
                    default_escape_flags => 'h',
                },
                Globals      => [],


=head2 Application


Inside this section, you can stuff anything you want. Have fun
