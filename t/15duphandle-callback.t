# Test script for Perl extension WWW::Curl::easy.
# Check out the file README for more info.

# Before `make install' is performed this script should be runnable with
# `make t/thisfile.t'. After `make install' it should work as `perl thisfile.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
use strict;

BEGIN { $| = 1; print "1..7\n"; }
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

my $body_called=0;
sub body_callback {
    my ($chunk,$handle)=@_;
    $body_called++;
    return length($chunk); # OK
}

my $head_called=0;
sub head_callback {
    my ($chunk,$handle)=@_;
    $head_called++;
    return length($chunk); # OK
}

$curl->setopt(CURLOPT_WRITEFUNCTION, \&body_callback);
$curl->setopt(CURLOPT_HEADERFUNCTION, \&head_callback);

print "ok ".++$count."\n";

$curl->setopt(CURLOPT_URL, $url);

# duplicate the handle
my $other_handle=$curl->duphandle();

# Go get it
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
if ($head_called<2) {
	print "not ";
}
print "ok ".++$count."\n";
if ($body_called<2) {
	print "not ";
}
print "ok ".++$count."\n";
exit;
