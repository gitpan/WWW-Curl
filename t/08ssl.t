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

my $sslversion95=0;
$sslversion95++ if (&WWW::Curl::easy::version() =~ m/SSL 0.9.5/); # 0.9.5 has buggy connect with some ssl sites

my $haveca=0;
if (-f "ca-bundle.crt") {
	$haveca=1;
}

# list of tests
#  site-url, verifypeer(0,1), verifyhost(0,2), result(0=ok, 1=fail), result-openssl0.9.5
my $url_list=[
	[ 'https://207.46.134.190/',  0, 0, 0 , 0 ], # www.microsoft.com
	[ 'https://207.46.249.222/',  0, 2, 1 , 1 ], # www.microsoft.com
	[ 'https://65.205.249.60/',  0, 0, 0 , 0 ], # www.verisign.com
	[ 'https://65.205.249.60/',  0, 2, 1 , 1 ], # www.verisign.com
	[ 'https://www.microsoft.com/', 0, 0, 0 , 0 ],
	[ 'https://www.microsoft.com/', 0, 0, 0 , 0 ],
	[ 'https://www.verisign.com/', 1, 2, 0 , 0 ], # verisign have broken ssl - do this first
	[ 'https://www.verisign.com/', 0, 0, 0 , 0 ], 
	[ 'https://www.verisign.com/', 0, 0, 0 , 0 ],
	[ 'https://www.verisign.com/', 0, 2, 0 , 0 ],
	[ 'https://lc2.law13.hotmail.passport.com/', 0, 0, 0 , 0 ],
	[ 'https://lc2.law13.hotmail.passport.com/', 0, 2, 0 , 0 ],
	[ 'https://lc2.law13.hotmail.passport.com/', 1, 2, 0 , 1 ], # fail on 0.9.5
	[ 'https://lc2.law13.hotmail.passport.com/', 1, 2, 0 , 1 ], # fail on 0.9.5

# libcurl < 7.9.3 crashes with more than 5 ssl hosts per handle.
	[ 'https://www.modssl.org/',  0, 0, 0 , 0],
	[ 'https://www.modssl.org/',  0, 2, 0 , 0],
	[ 'https://www.modssl.org/',  1, 0, 1 , 0],
	[ 'https://www.modssl.org/',  1, 2, 1 , 0],
];

print "1..".($#$url_list+6)."\n";
print "ok 1\n";

# Init the curl session
my $curl = WWW::Curl::easy->new();
if ($curl == 0) {
    print "not ";
}
print "ok ".++$count."\n";


$curl->setopt(CURLOPT_NOPROGRESS, 1);
$curl->setopt(CURLOPT_MUTE, 0);
#$curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
$curl->setopt(CURLOPT_TIMEOUT, 30);

my @myheaders;
$myheaders[0] = "User-Agent: Verifying SSL functions in perl interface for libcURL";
$curl->setopt(CURLOPT_HTTPHEADER, \@myheaders);
                                                                                       
open HEAD, ">head.out";
$curl->setopt(CURLOPT_WRITEHEADER, *HEAD);
print "ok ".++$count."\n";

open BODY, ">body.out";
$curl->setopt(CURLOPT_FILE,*BODY);
print "ok ".++$count."\n";

$curl->setopt(CURLOPT_FORBID_REUSE, 1);
$curl->setopt(CURLOPT_FRESH_CONNECT, 1);
#$curl->setopt(CURLOPT_SSL_CIPHER_LIST, "HIGH:MEDIUM");


print "ok ".++$count."\n";
$curl->setopt(CURLOPT_CAINFO,"ca-bundle.crt");                       

print STDERR "\n";
foreach my $test_list (@$url_list) {
    my ($url,$verifypeer,$verifyhost,$result,$result95)=@{$test_list};
    if ($verifypeer && !$haveca) { $result=1 } # expect to fail if no ca-bundle file
    if ($sslversion95) { $result=$result95 }; # change expectation	
 
    print STDERR "testing $url verify=$verifypeer at level $verifyhost expect ".($result?"fail":"pass")."\n";

    $curl->setopt(CURLOPT_SSL_VERIFYPEER,$verifypeer); # do verify 
    $curl->setopt(CURLOPT_SSL_VERIFYHOST,$verifyhost); # check name
    my $retcode;

    $curl->setopt(CURLOPT_URL, $url);

    $retcode=$curl->perform();
    if ( ($retcode != 0) != $result) {
	print STDERR "error $retcode ".$curl->errbuf."\n";
	print "not ";
    };
    print "ok ".++$count."\n";

}
