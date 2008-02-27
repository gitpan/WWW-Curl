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
print "1..7\n";
print "ok ".++$count."\n";

# Init the curl session
my $curl = WWW::Curl::Easy->new();
if ($curl == 0) {
    print "not ";
}
print "ok ".++$count."\n";

$curl->setopt(CURLOPT_NOPROGRESS, 1);
$curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
$curl->setopt(CURLOPT_TIMEOUT, 30);

open HEAD, ">head.out";
$curl->setopt(CURLOPT_WRITEHEADER, *HEAD);
print "ok ".++$count."\n";

open BODY, ">body.out";
$curl->setopt(CURLOPT_FILE,*BODY);
print "ok ".++$count."\n";

$curl->setopt(CURLOPT_URL, $url);

print "ok ".++$count."\n";
# Add some additional headers to the http-request:
my @myheaders;
$myheaders[0] = "Server: www";
$myheaders[1] = "User-Agent: Perl interface for libcURL";
$curl->setopt(CURLOPT_HTTPHEADER, \@myheaders);

# duplicate the handle
my $other_handle=$curl->duphandle();

# Go get it
#foreach my $x ($other_handle,$curl) {
foreach my $x ($other_handle,$curl) {
    my $retcode=$x->perform();
    if ($retcode == 0) {
	my $bytes=$x->getinfo(CURLINFO_SIZE_DOWNLOAD);
	my $realurl=$x->getinfo(CURLINFO_EFFECTIVE_URL);
	my $httpcode=$x->getinfo(CURLINFO_HTTP_CODE);
    } else {
	print "not ";
    }
    print "ok ".++$count."\n";
}
exit;
