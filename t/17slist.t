# Test script for Perl extension WWW::Curl::easy.
# Check out the file README for more info.

# Before `make install' is performed this script should be runnable with
# `make t/thisfile.t'. After `make install' it should work as `perl thisfile.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
use strict;

use WWW::Curl::easy;

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

# we need the real printenv cgi for these tests, so skip if
# our test URL is not a printenv
#

if ($url !~ m/printenv/) {
	print "1..1\nok 1\n";
	exit;
}
print "1..6\n";


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


sub body_callback {
    my ($chunk,$handle)=@_;
    ${$handle}.=$chunk;
    return length($chunk); # OK
}
$curl->setopt(CURLOPT_WRITEFUNCTION, \&body_callback);

my $body="";
$curl->setopt(CURLOPT_FILE,\$body);
print "ok ".++$count."\n";

$curl->setopt(CURLOPT_URL, $url);

print "ok ".++$count."\n";
# Add some additional headers to the http-request:
# Check that the printenv script sends back FOO=bar somewhere
# This checks that all headers were sent.
my @myheaders;
$myheaders[0] = "Baz: xyzzy";
$myheaders[1] = "Foo: bar";
$curl->setopt(CURLOPT_HTTPHEADER, \@myheaders);
                                                                        
# Go get it
my $retcode=$curl->perform();
if ($retcode == 0) {
	if ($body !~ m/FOO="bar"/) {            
		print "not ";
	}
} else {
   # We can acces the error message in $errbuf here
#    print STDERR "$retcode / ".$curl->errbuf."\n";
    print "not ";
}
print "ok ".++$count."\n";

exit;
