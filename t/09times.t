# Test script for Perl extension WWW::Curl::easy.
# Check out the file README for more info.

# Before `make install' is performed this script should be runnable with
# `make t/thisfile.t'. After `make install' it should work as `perl thisfile.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
use strict;

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $::loaded;}
use WWW::Curl::easy ;

$::loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print STDERR "transfer times test will only compile/run on curl >= 7.9.1\n";
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
my $curl = WWW::Curl::easy->new();
if ($curl == 0) {
    print "not ";
}
print "ok ".++$count."\n";

$curl->setopt(CURLOPT_NOPROGRESS, 1);
$curl->setopt(CURLOPT_MUTE, 1);
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
    print STDERR "$bytes bytes read ";
    my $realurl=$curl->getinfo(CURLINFO_EFFECTIVE_URL);
    my $httpcode=$curl->getinfo(CURLINFO_HTTP_CODE);
    print STDERR "effective fetched url (http code: $httpcode) was: $url ";
} else {
   # We can acces the error message in errbuf here
    print STDERR "$retcode / ".$curl->errbuf."\n";
    print "not ";
}
print "ok ".++$count."\n";

my $start=$curl->getinfo(CURLINFO_STARTTRANSFER_TIME);
my $total=$curl->getinfo(CURLINFO_TOTAL_TIME);
my $dns=$curl->getinfo(CURLINFO_NAMELOOKUP_TIME);
my $conn=$curl->getinfo(CURLINFO_CONNECT_TIME);
my $pre=$curl->getinfo(CURLINFO_PRETRANSFER_TIME);
print STDERR "times are: dns: $dns, connect: $conn, pretransfer: $pre, starttransfer: $start, total: $total.\n";

print "ok ".++$count."\n";

exit;
