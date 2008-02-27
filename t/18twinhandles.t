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
my $defurl=$ENV{CURL_TEST_URL} || "http://www.google.com/";
my $url = prompt("# Please enter an URL to fetch",$defurl);
if (!$url) {
    print "1..0 # No test URL supplied - skipping test\n";
    exit;
}
print "1..8\n";
print "ok ".++$count."\n";

my $header_called=0;
sub header_callback {
    $header_called++; return length($_[0])
};

my $body_called=0;
sub body_callback {
	my ($chunk,$handle)=@_;
	$body_called++;
	return length($chunk); # OK
}


# Init the curl session
my $curl1 = WWW::Curl::Easy->new();
if ($curl1 == 0) {
    print "not ";
}
print "ok ".++$count."\n";

my $curl2 = WWW::Curl::Easy->new();
if ($curl2 == 0) {
    print "not ";
}
print "ok ".++$count."\n";

foreach my $handle ($curl1,$curl2) {
$handle->setopt(CURLOPT_NOPROGRESS, 1);
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


print "# next test will fail on libcurl < 7.7.2\n";
print "not " if (!$header_called); # ok if you have a libcurl <7.7.2
print "ok ".++$count."\n";

print "not " if (!$body_called);
print "ok ".++$count."\n";
