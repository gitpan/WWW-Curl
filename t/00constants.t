#!perl
use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok( 'WWW::Curl::Easy' ); }

ok (CURLOPT_URL == 10000+2, "Constant loaded ok");
