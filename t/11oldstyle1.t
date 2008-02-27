#!perl

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
use strict;

END {print "not ok 1\n" unless $::loaded;}
use WWW::Curl::Easy;

$::loaded = 1;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#
# Test backwards compatability of the Easy interface with the
# non-OO 'easy' interface version
#
# NOTE: You still need to 'use' the new module name WWW::Curl::Easy (note upper case)
# but you don't have to change all the rest of the code, although support for the old
# names will go away in a future version.
#

my $count=0;


use ExtUtils::MakeMaker qw(prompt);

# Read URL to get, defaulting to environment variable if supplied
my $defurl=$ENV{CURL_TEST_URL} || "http://www.google.com/";
my $url = prompt("# Please enter an URL to fetch",$defurl);
if (!$url) {
    print "1..0 # No test URL supplied - skipping test\n";
    exit;
}
print "1..6\n";
print "ok ".++$count."\n";

# Init the curl session
my $curl = WWW::Curl::easy::init();
if ($curl == 0) {
    print "not ";
}
print "ok ".++$count."\n";

WWW::Curl::easy::setopt($curl, CURLOPT_NOPROGRESS, 1);
WWW::Curl::easy::setopt($curl, CURLOPT_FOLLOWLOCATION, 1);
WWW::Curl::easy::setopt($curl, CURLOPT_TIMEOUT, 30);

open HEAD, ">head.out";
WWW::Curl::easy::setopt($curl, CURLOPT_WRITEHEADER, *HEAD);
print "ok ".++$count."\n";

open BODY, ">body.out";
WWW::Curl::easy::setopt($curl, CURLOPT_FILE,*BODY);
print "ok ".++$count."\n";

WWW::Curl::easy::setopt($curl, CURLOPT_URL, $url);

print "ok ".++$count."\n";

my $read_max=1000;

sub read_callb
{
    my ($maxlen,$sv)=@_;
	if ($read_max > 0) {
		my $len=int($read_max/3)+1;
		my $data = chr(ord('A')+rand(26))x$len;
		$read_max=$read_max-length($data);
		return $data;
	} else {
		return "";
	}
}  

#
# test post/read callback functions - requires a url which accepts posts, or it fails!
#

WWW::Curl::easy::setopt($curl,CURLOPT_READFUNCTION,\&read_callb);
WWW::Curl::easy::setopt($curl,CURLOPT_INFILESIZE,$read_max );
WWW::Curl::easy::setopt($curl,CURLOPT_UPLOAD,1 );
WWW::Curl::easy::setopt($curl,CURLOPT_CUSTOMREQUEST,"POST" );
                                                       
if ($curl->perform() != 0) {
	print "not ";
};
print "ok ".++$count."\n";
