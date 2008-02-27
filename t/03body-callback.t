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

# The header callback will only be called if your libcurl has the
# CURLOPT_HEADERFUNCTION supported, otherwise your headers
# go to CURLOPT_WRITEFUNCTION instead...
#

my $header_called=0;
sub header_callback {
	#print STDERR "header callback called\n";
	$header_called=1; return length($_[0])
	};

# test for sub reference and head callback
$curl->setopt(CURLOPT_HEADERFUNCTION, \&header_callback);

my $body_called=0;
sub body_callback {
	my ($chunk,$handle)=@_;
#	print STDERR "body callback called with ",length($chunk)," bytes\n";
#	print STDERR "data=$chunk\n";
	$body_called++;
	return length($chunk); # OK
}


# test for ref to sub and body callback
my $body_ref=\&body_callback;
$curl->setopt(CURLOPT_WRITEFUNCTION, $body_ref);

if ($curl->perform() != 0) {
	print "not ";
};
print "ok ".++$count."\n";


print "# next test will fail on libcurl < 7.7.2\n";
print "not " if (!$header_called); # ok if you have a libcurl <7.7.2
print "ok ".++$count."\n";

print "not " if (!$body_called);
print "ok ".++$count."\n";
