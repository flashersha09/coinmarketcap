#!/usr/bin/env perl

use Mojo::Server;
use File::Basename;

use lib dirname (__FILE__) . '/lib';

require Mojolicious::Commands;
Mojolicious::Commands->start_app('App');