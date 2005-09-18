#!perl

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
use strict;

END {print "not ok 1\n" unless $::loaded;}
use WWW::Curl::Easy ;

$::loaded = 1;

######################### End of black magic.


print  "# transfer times test will only compile/run on curl >= 7.9.1\n";
my $count=0;


use ExtUtils::MakeMaker qw(prompt);

# Read URL to get, defaulting to environment variable if supplied
my $defurl=$ENV{CURL_TEST_URL} || "";
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
my @myheaders=();
$myheaders[0] = "Server: www";
$myheaders[1] = "User-Agent: Perl interface for libcURL";
$curl->setopt(CURLOPT_HTTPHEADER, \@myheaders);
                                                                        
# Go get it
my $retcode=$curl->perform();
if ($retcode == 0) {
    my $bytes=$curl->getinfo(CURLINFO_SIZE_DOWNLOAD);
    print "# $bytes bytes read ";
    my $realurl=$curl->getinfo(CURLINFO_EFFECTIVE_URL);
    my $httpcode=$curl->getinfo(CURLINFO_HTTP_CODE);
    print "# effective fetched url (http code: $httpcode) was: $url\n";
} else {
   # We can acces the error message in errbuf here
    print "# $retcode / ".$curl->errbuf."\n";
    print "not ";
}
print "ok ".++$count."\n";

my $start=$curl->getinfo(CURLINFO_STARTTRANSFER_TIME);
my $total=$curl->getinfo(CURLINFO_TOTAL_TIME);
my $dns=$curl->getinfo(CURLINFO_NAMELOOKUP_TIME);
my $conn=$curl->getinfo(CURLINFO_CONNECT_TIME);
my $pre=$curl->getinfo(CURLINFO_PRETRANSFER_TIME);
print "# times are: dns: $dns, connect: $conn, pretransfer: $pre, starttransfer: $start, total: $total.\n";

print "ok ".++$count."\n";

exit;
