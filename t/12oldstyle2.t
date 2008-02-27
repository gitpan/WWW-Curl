#!perl

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
use strict;

END {print "not ok 1\n" unless $::loaded;}
use WWW::Curl::Easy ;

$::loaded = 1;

######################### End of black magic.

#
# Test backwards compatability of the interface
#

my $count=0;


use ExtUtils::MakeMaker qw(prompt);

# Read URL to get, defaulting to environment variable if supplied
my $defurl=$ENV{CURL_TEST_URL} || "http://www.google.com/";
my $url = prompt("# Please enter an URL to fetch",$defurl);
if (!$url) {
    print "1..0 # No test URL supplied - skipping test\n";
    exit;
}
print "1..8\n";
print "ok ".++$count."\n";

# Init the curl session
my $curl = WWW::Curl::easy::init();
if ($curl == 0) {
    print "not ";
}
print "ok ".++$count."\n";

WWW::Curl::easy::setopt($curl, CURLOPT_NOPROGRESS, 1);
WWW::Curl::easy::setopt($curl, CURLOPT_FOLLOWLOCATION, 1);
WWW::Curl::easy::setopt($curl, CURLOPT_TIMEOUT, 30);

open HEAD, ">head.out";
WWW::Curl::easy::setopt($curl, CURLOPT_WRITEHEADER, *HEAD);
print "ok ".++$count."\n";

open BODY, ">body.out";
WWW::Curl::easy::setopt($curl, CURLOPT_FILE,*BODY);
print "ok ".++$count."\n";

# avoid single use warning
$::errbuf="";
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
    WWW::Curl::easy::getinfo($curl, CURLINFO_EFFECTIVE_URL, $realurl);
    WWW::Curl::easy::getinfo($curl, CURLINFO_HTTP_CODE, $httpcode);
} else {
   # We can acces the error message in $::errbuf here
    print "not ";
}
print "ok ".++$count."\n";

my ($total,$dns,$conn,$pre,$start)=(0,0,0,0,0);
#WWW::Curl::easy::getinfo($curl, CURLINFO_STARTTRANSFER_TIME, $start);
WWW::Curl::easy::getinfo($curl, CURLINFO_TOTAL_TIME, $total);
WWW::Curl::easy::getinfo($curl, CURLINFO_NAMELOOKUP_TIME, $dns);
WWW::Curl::easy::getinfo($curl, CURLINFO_CONNECT_TIME, $conn);
WWW::Curl::easy::getinfo($curl, CURLINFO_PRETRANSFER_TIME, $pre);
print "# times are: dns: $dns, connect: $conn, pretransfer: $pre, starttransfer: $start, total: $total.\n";

print "ok ".++$count."\n";

exit;
