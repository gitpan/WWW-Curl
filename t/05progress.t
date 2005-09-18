#!perl

######################### We start with some black magic to print on failure.

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

print "1..9\n";

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

$curl->setopt(CURLOPT_NOPROGRESS, 0);
print "ok ".++$count."\n";

# inline progress function
# tests for inline subs and progress callback
# - progress callback must return 'true' on each call.

$curl->setopt(CURLOPT_PROGRESSDATA,"making progress!");

my $progress_called;
my $last_dlnow=0;
sub prog_callb
{
    my ($clientp,$dltotal,$dlnow,$ultotal,$ulnow)=@_;
#    print STDERR "\nperl progress_callback has been called!\n";
#    print STDERR "clientp: $clientp, dltotal: $dltotal, dlnow: $dlnow, ultotal: $ultotal, ";
#    print STDERR "ulnow: $ulnow\n";
    $last_dlnow=$dlnow;
    $progress_called++;
    return 0;
}                        

$curl->setopt(CURLOPT_PROGRESSFUNCTION, \&prog_callb);

# Turn progress meter back on - this doesnt work in older libcurls -  once its off, its off.
$curl->setopt(CURLOPT_NOPROGRESS, 0);

if ($curl->perform() != 0) {
	print "not ";
};
print "ok ".++$count."\n";

print "not " if (!$progress_called);
print "ok ".++$count."\n";

print "not " if ($last_dlnow == 0);
print "ok ".++$count."\n";

