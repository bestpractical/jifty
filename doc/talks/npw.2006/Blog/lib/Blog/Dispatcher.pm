 package Blog::Dispatcher;
 use Jifty::Dispatcher -base;

 before '*' => run {
    my $top = Jifty->web->navigation;
    $top->child('List Entries' => url => '/');
    $top->child('New Entry'    => url => '/new_entry');
 }
 on '/' => run {
     my $entries =
        Blog::Model::EntryCollection->new();
     $entries->unlimit();

     set entries => $entries;
 };
 on '/new_entry' => run {
     set create => Jifty->web->new_action(
         class => 'CreateEntry',
         moniker => 'new_entry',
     );
 };

1;
