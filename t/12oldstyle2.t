# Test script for Perl extension WWW::Curl::easy.
# Check out the file README for more info.

# Before `make install' is performed this script should be runnable with
# `make t/thisfile.t'. After `make install' it should work as `perl thisfile.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
use strict;

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $::loaded;}
use WWW::Curl::easy ;

$::loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#
# Test backwards compatability of the interface
#

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

# Init the curl session
my $curl = WWW::Curl::easy::init();
if ($curl == 0) {
    print "not ";
}
print "ok ".++$count."\n";

WWW::Curl::easy::setopt($curl, CURLOPT_NOPROGRESS, 1);
WWW::Curl::easy::setopt($curl, CURLOPT_MUTE, 1);
WWW::Curl::easy::setopt($curl, CURLOPT_FOLLOWLOCATION, 1);
WWW::Curl::easy::setopt($curl, CURLOPT_TIMEOUT, 30);

open HEAD, ">head.out";
WWW::Curl::easy::setopt($curl, CURLOPT_WRITEHEADER, *HEAD);
print "ok ".++$count."\n";

open BODY, ">body.out";
WWW::Curl::easy::setopt($curl, CURLOPT_FILE,*BODY);
print "ok ".++$count."\n";

$::errbuf="";
WWW::Curl::easy::setopt($curl, CURLOPT_ERRORBUFFER, "::errbuf");
print "ok ".++$count."\n";

WWW::Curl::easy::setopt($curl, CURLOPT_URL, $url);

print "ok ".++$count."\n";
# Add some additional headers to the http-request:
my @myheaders=();
$myheaders[0] = "Server: www";
$myheaders[1] = "User-Agent: Perl interface for libcURL";
WWW::Curl::easy::setopt($curl, CURLOPT_HTTPHEADER, \@myheaders);
                                                                        
my $bytes=0;
my $realurl=0;
my $httpcode=0;

# Go get it
my $retcode=$curl->perform();
if ($retcode == 0) {
    WWW::Curl::easy::getinfo($curl, CURLINFO_SIZE_DOWNLOAD, $bytes);
#    print STDERR "$bytes bytes read ";
    WWW::Curl::easy::getinfo($curl, CURLINFO_EFFECTIVE_URL, $realurl);
    WWW::Curl::easy::getinfo($curl, CURLINFO_HTTP_CODE, $httpcode);
#    print STDERR "effective fetched url (http code: $httpcode) was: $url ";
} else {
   # We can acces the error message in $::errbuf here
#    print STDERR "$retcode / $::errbuf\n";
    print "not ";
}
print "ok ".++$count."\n";

my ($total,$dns,$conn,$pre,$start)=(0,0,0,0,0);
#WWW::Curl::easy::getinfo($curl, CURLINFO_STARTTRANSFER_TIME, $start);
WWW::Curl::easy::getinfo($curl, CURLINFO_TOTAL_TIME, $total);
WWW::Curl::easy::getinfo($curl, CURLINFO_NAMELOOKUP_TIME, $dns);
WWW::Curl::easy::getinfo($curl, CURLINFO_CONNECT_TIME, $conn);
WWW::Curl::easy::getinfo($curl, CURLINFO_PRETRANSFER_TIME, $pre);
print STDERR "\ntimes are: dns: $dns, connect: $conn, pretransfer: $pre, starttransfer: $start, total: $total.\n";

print "ok ".++$count."\n";

exit;
