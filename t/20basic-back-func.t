#!perl

#
# $Id: 20basic-back-func.t,v 1.3 2004/04/20 13:23:58 crisb Exp $
#
# Test script for back compatability for Curl::easy in WWW::Curl::easy
# Test calling Curl::easy in the function style

use strict;

print "1..0 # TODO skipping broken backwards namespace test\n";
exit;

__END__;

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $::loaded;}
use Curl::easy;

$::loaded = 1;

######################### End of black magic.


my $count=0;

# Read URL to get
my $defurl = "http://localhost/cgi-bin/printenv";
my $url;
if (defined ($ENV{CURL_TEST_URL})) {
	$url=$ENV{CURL_TEST_URL};
} else {
$url = "";
print "# Please enter an URL to fetch [$defurl]: ";
$url = <STDIN>;
if ($url =~ /^\s*\n/) {
    $url = $defurl;
}
}

# Init the curl session
my $curl = Curl::easy::init();
if ($curl == 0) {
    print "not ";
}
print "ok ".++$count."\n";

Curl::easy::setopt($curl,CURLOPT_NOPROGRESS, 1);
Curl::easy::setopt($curl,CURLOPT_VERBOSE, 0);

open HEAD, ">head.out";
Curl::easy::setopt($curl,CURLOPT_WRITEHEADER, *HEAD);
print "ok ".++$count."\n";

open BODY, ">body.out";
Curl::easy::setopt($curl,CURLOPT_FILE,*BODY);
print "ok ".++$count."\n";

Curl::easy::setopt($curl,CURLOPT_URL, $url);

print "ok ".++$count."\n";
# Add some additional headers to the http-request:
my @myheaders;
$myheaders[0] = "Server: www";
$myheaders[1] = "User-Agent: Perl interface for libcURL";
Curl::easy::setopt($curl,CURLOPT_HTTPHEADER, \@myheaders);
                                                                        
# Go get it
my $retcode=$curl->perform();
if ($retcode == 0) {
    my $bytes=Curl::easy::getinfo($curl,CURLINFO_SIZE_DOWNLOAD);
#    print STDERR "$bytes bytes read ";
    my $realurl=Curl::easy::getinfo($curl,CURLINFO_EFFECTIVE_URL);
    my $httpcode=Curl::easy::getinfo($curl,CURLINFO_HTTP_CODE);
#    print STDERR "effective fetched url (http code: $httpcode) was: $url ";
print "ok ".++$count."\n";
} else {
   # We can acces the error message in $errbuf here
    print "not ok ".++$count." $retcode / ".Curl::easy::errbuf($curl)."\n";
}

exit;
