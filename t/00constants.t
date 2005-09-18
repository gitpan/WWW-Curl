#!perl

# Test script for Perl extension WWW::Curl::Easy.
# Check out the file README for more info.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl thisfile.t'

######################### We start with some black magic to print on failure.

use Benchmark;
use strict;

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $::loaded;}
use WWW::Curl::Easy;

$::loaded = 1;

######################## End of black magic.

my $count=0;
print "ok ".++$count."\n";

my $version=&WWW::Curl::Easy::version();

print "ok ".++$count." testing curl version $version\n";

# test constants are loaded OK
if (CURLOPT_URL != 10000+2) {
    print "not ";
}

print "ok ".++$count."\n";

exit;
