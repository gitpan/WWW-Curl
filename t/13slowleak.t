# Test script for Perl extension WWW::Curl::easy.
# Check out the file README for more info.

# Before `make install' is performed this script should be runnable with
# `make t/thisfile.t'. After `make install' it should work as `perl thisfile.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
use strict;

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $::loaded;}
use WWW::Curl::easy;

$::loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $count=1;

# Read URL to get
my $defurl = "http://localhost/cgi-bin/printenv";
my $url;
if (defined ($ENV{CURL_TEST_URL})) {
	$url=$ENV{CURL_TEST_URL};
} else {
$url = "";
print "Please enter an URL to fetch [$defurl]: ";
$url = <STDIN>;
if ($url =~ /^\s*\n/) {
    $url = $defurl;
}
}

#
# There is a slow leak per curl handle init/cleanup
# somewhere. Demonstrated here..
#
foreach my $j (1..200) {

# Init the curl session
my $curl = WWW::Curl::easy->new() or die "cannot curl";

$curl->setopt(CURLOPT_NOPROGRESS, 1);
$curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
$curl->setopt(CURLOPT_TIMEOUT, 30);

open HEAD, ">head.out";
WWW::Curl::easy::setopt($curl, CURLOPT_WRITEHEADER, *HEAD);
open BODY, ">body.out";
WWW::Curl::easy::setopt($curl, CURLOPT_FILE,*BODY);

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
	print STDERR "$retcode / ".$curl->errbuf."\n";
	print "not ";
    }
}
print "ok 2\n";

WWW::Curl::easy::global_cleanup;
exit;
