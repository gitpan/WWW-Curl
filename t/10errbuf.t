#!perl

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
use strict;

END {print "not ok 1\n" unless $::loaded;}
use WWW::Curl::Easy;

$::loaded = 1;

######################### End of black magic.

my $count=0;

use ExtUtils::MakeMaker qw(prompt);

# Read URL to get, defaulting to environment variable if supplied
my $defurl=$ENV{CURL_TEST_URL} || "http://www.google.com/";
my $url = prompt("# Please enter an URL to fetch",$defurl);
if (!$url) {
    print "1..0 # No test URL supplied - skipping test\n";
    exit;
}

print "1..5\n";

print "ok ".++$count."\n";

# Init the curl session
my $curl = WWW::Curl::Easy->new();
if ($curl == 0) {
    print "not ";
}
print "ok ".++$count."\n";

$curl->setopt(CURLOPT_NOPROGRESS, 1);

open NEW_ERROR,">error.out" or die;
$curl->setopt(CURLOPT_STDERR, *NEW_ERROR);
print "ok ".++$count."\n";

# create a (hopefully) bad URL, so we get an error
$curl->setopt(CURLOPT_URL, "badprotocol://127.0.0.1:2"); 

print "ok ".++$count."\n";
                                                                        
# Go get it
my $retcode=$curl->perform();
if ($retcode == 0) {
    print "not ";
} else {
    print "not " if ($curl->errbuf eq "");
}
print "ok ".++$count."\n";

exit;
