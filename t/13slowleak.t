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
my $defurl=$ENV{CURL_TEST_URL} || "";
my $url = prompt("# Please enter an URL to fetch",$defurl);
if (!$url) {
    print "1..0 # No test URL supplied - skipping test\n";
    exit;
}
print "1..2\n";
print "ok ".++$count."\n";

#
# There was a slow leak per curl handle init/cleanup
# somewhere. Demonstrated here if you raise the number
# of iterations e.g.:
#
# foreach my $j (1..200) {
foreach my $j (1..2) {

# Init the curl session
my $curl = WWW::Curl::Easy->new() or die "cannot curl";

$curl->setopt(CURLOPT_NOPROGRESS, 1);
$curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
$curl->setopt(CURLOPT_TIMEOUT, 30);

open HEAD, ">head.out";
WWW::Curl::Easy::setopt($curl, CURLOPT_WRITEHEADER, *HEAD);
open BODY, ">body.out";
WWW::Curl::Easy::setopt($curl, CURLOPT_FILE,*BODY);

$curl->setopt(CURLOPT_URL, $url);

# Add some additional headers to the http-request:
my @headers=(
    "Server: www",
    "User-Agent: Perl interface for libcURL"
);
#$curl->setopt(CURLOPT_HTTPHEADER,  [
#    "Server: www",
#    "User-Agent: Perl interface for libcURL"
#    ]);
                                                                        
my $httpcode=0;

# Go get it
    my $retcode=$curl->perform();
    if ($retcode == 0) {
	my $bytes=$curl->getinfo(CURLINFO_SIZE_DOWNLOAD);
	my $realurl=$curl->getinfo(CURLINFO_EFFECTIVE_URL);
	my $httpcode=$curl->getinfo(CURLINFO_HTTP_CODE);
    } else {
	print "not ok $retcode / ".$curl->errbuf."\n";
    } 
}
print "ok 2\n";

WWW::Curl::Easy::global_cleanup;
exit;
