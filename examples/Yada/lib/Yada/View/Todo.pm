package Yada::View::Todo;
use strict;
use Jifty::View::Declare -base;
use base 'Jifty::View::Declare::CRUD';

sub object_type { 'Todo' }

sub fragment_for { return "/todo/$_[1]" }


1;
