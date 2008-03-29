#!perl

use strict;
use warnings;
use lib 'inc';
use lib 'blib/lib';
use lib 'blib/arch';
use Test::More tests => 26;

BEGIN { use_ok( 'WWW::Curl::Easy' ); }

my $url = $ENV{CURL_TEST_URL} || "http://www.google.com";
my $other_handle;
open (HEAD, "+>", undef);
{
# Init the curl session
my $curl = WWW::Curl::Easy->new();
ok($curl, 'Curl session initialize returns something');
ok(ref($curl) eq 'WWW::Curl::Easy', 'Curl session looks like an object from the WWW::Curl::Easy module');

ok(! $curl->setopt(CURLOPT_NOPROGRESS, 1), "Setting CURLOPT_NOPROGRESS");
ok(! $curl->setopt(CURLOPT_FOLLOWLOCATION, 1), "Setting CURLOPT_FOLLOWLOCATION");
ok(! $curl->setopt(CURLOPT_TIMEOUT, 30), "Setting CURLOPT_TIMEOUT");

ok(! $curl->setopt(CURLOPT_WRITEHEADER, *HEAD), "Setting CURLOPT_WRITEHEADER");

open (BODY, "+>", undef);
ok(! $curl->setopt(CURLOPT_FILE,*BODY), "Setting CURLOPT_FILE");


my @myheaders;
$myheaders[0] = "Server: www";
$myheaders[1] = "User-Agent: Perl interface for libcURL";
ok(! $curl->setopt(CURLOPT_HTTPHEADER, \@myheaders), "Setting CURLOPT_HTTPHEADER");

my $body_called = 0;
sub body_callback {
    my ($chunk,$handle)=@_;
    $body_called++;
    return length($chunk); # OK
}

my $head_called = 0;
sub head_callback {
    my ($chunk,$handle)=@_;
    $head_called++;
    return length($chunk); # OK
}

ok(! $curl->setopt(CURLOPT_WRITEFUNCTION, \&body_callback), "Setting CURLOPT_WRITEFUNCTION callback");
ok(! $curl->setopt(CURLOPT_HEADERFUNCTION, \&head_callback), "Setting CURLOPT_HEADERFUNCTION callback");

ok(! $curl->setopt(CURLOPT_URL, $url), "Setting CURLOPT_URL");

# duplicate the handle
$other_handle = $curl->duphandle();
ok($other_handle, 'duphandle seems to return something');
ok(ref($other_handle) eq 'WWW::Curl::Easy', 'Dup handle looks like an object from the WWW::Curl::Easy module');

foreach my $x ($other_handle,$curl) {
    my $retcode=$x->perform();
    ok(!$retcode, "Handle return code check");
    if ($retcode == 0) {
	my $bytes=$x->getinfo(CURLINFO_SIZE_DOWNLOAD);
	my $realurl=$x->getinfo(CURLINFO_EFFECTIVE_URL);
	my $httpcode=$x->getinfo(CURLINFO_HTTP_CODE);
    }
}
ok( $head_called >= 2, "Header callback seems to have worked");
ok( $body_called >= 2, "Body callback seems to have worked");

}


ok(! $other_handle->setopt(CURLOPT_URL, $url), "Setting CURLOPT_URL");
my $retcode=$other_handle->perform();
ok(!$retcode, "Handle return code check");
ok( 1, "We survive DESTROY time for the original handle");
ok( head_callback('1',undef), "We can still access the callbacks");
my $third = $other_handle->duphandle();
ok($third, 'duphandle seems to return something');
ok(ref($third) eq 'WWW::Curl::Easy', 'Dup handle looks like an object from the WWW::Curl::Easy module');

foreach my $x ($other_handle,$third) {
    my $retcode=$x->perform();
    ok(!$retcode, "Handle return code check");
    if ($retcode == 0) {
	my $bytes=$x->getinfo(CURLINFO_SIZE_DOWNLOAD);
	my $realurl=$x->getinfo(CURLINFO_EFFECTIVE_URL);
	my $httpcode=$x->getinfo(CURLINFO_HTTP_CODE);
    }
}
