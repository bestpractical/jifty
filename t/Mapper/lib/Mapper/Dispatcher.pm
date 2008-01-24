#!/usr/bin/env perl
package Mapper::Dispatcher;
use Jifty::Dispatcher -base;

before '*' => run {
    Jifty->api->allow('GetGrail');
    Jifty->api->allow('CrossBridge');
};


1;

