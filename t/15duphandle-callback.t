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
