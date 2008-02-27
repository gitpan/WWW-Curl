#!perl

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
use strict;
use ExtUtils::MakeMaker qw(prompt);

END {print "not ok 1\n" unless $::loaded;}
use WWW::Curl::Easy;

$::loaded = 1;

######################### End of black magic.

my $count=0;


# Read URL to get, defaulting to environment variable if supplied
my $defurl=$ENV{CURL_TEST_URL} || "http://www.google.com/";
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

my $body_abort_called=0;
sub body_abort_callback {
	my ($chunk,$sv)=@_;
#	print STDERR "body abort callback called with ",length($chunk)," bytes\n";
	$body_abort_called++;
	return  -1; # signal a failure
}

# test we can abort a request mid-way
my $body_abort_ref=\&body_abort_callback;
$curl->setopt(CURLOPT_WRITEFUNCTION, $body_abort_ref);

if ($curl->perform() == 0) { # reverse test - this should have failed
	print "not ";
};
print "ok ".++$count."\n";

print "not " if (!$body_abort_called); # should have been called
print "ok ".++$count."\n";
