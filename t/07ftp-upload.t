# Test script for Perl extension WWW::Curl::easy.
# Check out the file README for more info.

# Before `make install' is performed this script should be runnable with
# `make t/thisfile.t'. After `make install' it should work as `perl thisfile.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
use strict;

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
my $defurl = "ftp://ftp\@ftp.perl.org/pub/incoming/curl-easy-test.".time.".".$$;
my $url;
if (defined ($ENV{CURL_TEST_URL_FTP})) {
	$url=$ENV{CURL_TEST_URL_FTP};
};

if (!$url) {
	print STDERR "Skipping ftp test - need ftp upload server\n";
	print "1..2\n";
	print "ok 2\n";
	exit;
}

print "1..8\n"; 
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

open BODY, ">body.out";
$curl->setopt(CURLOPT_FILE,*BODY);
print "ok ".++$count."\n";

$curl->setopt(CURLOPT_URL, $url);

print "ok ".++$count."\n";

sub passwd_callb
{
    my ($clientp,$prompt,$buflen)=@_;
    print STDERR "\nperl passwd_callback has been called!\n";
    print STDERR "clientp: $clientp, prompt: $prompt, buflen: $buflen\n";
    my $data;
    if (defined($ENV{CURL_TEST_URL_FTP})) {
	    print STDERR "\nEnter max $buflen characters for $prompt ";
	    $data = <STDIN>;
	    chomp($data);
	} else {
	    print STDERR "\nReplying to $prompt\n";
	    $data = "ftp\@";
    }
    return (0,$data);
}                                                         

# Now do an ftp upload:


$curl->setopt(CURLOPT_UPLOAD, 1);


my $read_max=1000;
$curl->setopt(CURLOPT_INFILESIZE,$read_max );   
print "ok ".++$count."\n";
 
sub read_callb
{
    my ($maxlen,$sv)=@_;
    print STDERR "\nperl read_callback has been called!\n";
    print STDERR "max data size: $maxlen - $read_max bytes needed\n";

	if ($read_max > 0) {
                my $len=int($read_max/3)+1;
                my $data = chr(ord('A')+rand(26))x$len;
                print STDERR "generated max/3=", int($read_max/3)+1, " characters to be uploaded - $data.\n";
                $read_max=$read_max-length($data);
                return $data;
        } else {
                return "";
        }
}
               
# Use perl read callback to read data to be uploaded
$curl->setopt(CURLOPT_READFUNCTION, \&read_callb);

# Use perl passwd callback to read password for login to ftp server
$curl->setopt(CURLOPT_PASSWDFUNCTION, \&passwd_callb);

print "ok ".++$count."\n";

# Go get it
my $code;
if (($code=$curl->perform()) == 0) {
    my $bytes=$curl->getinfo(CURLINFO_SIZE_UPLOAD);
    print STDERR "$bytes bytes transferred\n";
} else {
    # We can acces the error message in $errbuf here
    print STDERR "ftpcode= $code, errbuf='.$curl->errbuf.'\n";
    print "not ";
}
print "ok ".++$count."\n";
