# Test script for Perl extension WWW::Curl::easy.
# Check out the file README for more info.

# Before `make install' is performed this script should be runnable with
# `make t/thisfile.t'. After `make install' it should work as `perl thisfile.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
use strict;

BEGIN { $| = 1; print "1..8\n"; }
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

my $header_called=0;
sub header_callback {
    $header_called++; return length($_[0])
};

my $body_called=0;
sub body_callback {
	my ($chunk,$handle)=@_;
#	print STDERR "body callback called with ",length($chunk)," bytes\n";
#	print STDERR "data=$chunk\n";
	$body_called++;
	return length($chunk); # OK
}


# Init the curl session
my $curl1 = WWW::Curl::easy->new();
if ($curl1 == 0) {
    print "not ";
}
print "ok ".++$count."\n";

my $curl2 = WWW::Curl::easy->new();
if ($curl2 == 0) {
    print "not ";
}
print "ok ".++$count."\n";

foreach my $handle ($curl1,$curl2) {
$handle->setopt(CURLOPT_NOPROGRESS, 1);
$handle->setopt(CURLOPT_MUTE, 1);
$handle->setopt(CURLOPT_FOLLOWLOCATION, 1);
$handle->setopt(CURLOPT_TIMEOUT, 30);

my $body_ref=\&body_callback;
$handle->setopt(CURLOPT_WRITEFUNCTION, $body_ref);
$handle->setopt(CURLOPT_HEADERFUNCTION, \&header_callback);

}

print "ok ".++$count."\n";


$curl1->setopt(CURLOPT_URL, "error:bad-url"); # deliberate error
$curl2->setopt(CURLOPT_URL, $url);

my $code1=$curl1->perform();
if ($code1 == 0) { # should fail!
	print "not ";
};
print "ok ".++$count."\n";

my $code2=$curl2->perform();
if ($code2 != 0) {
	print "not ";
};
print "ok ".++$count."\n";


print STDERR "next test will fail on libcurl < 7.7.2\n";
print "not " if (!$header_called); # ok if you have a libcurl <7.7.2
print "ok ".++$count."\n";

print "not " if (!$body_called);
print "ok ".++$count."\n";
