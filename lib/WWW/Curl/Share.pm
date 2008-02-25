package WWW::Curl::Share;

use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);

use WWW::Curl;
require Exporter;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(
CURLSHOPT_LAST
CURLSHOPT_LOCKFUNC
CURLSHOPT_NONE
CURLSHOPT_SHARE
CURLSHOPT_UNLOCKFUNC
CURLSHOPT_UNSHARE
CURLSHOPT_USERDATA
CURL_LOCK_DATA_CONNECT
CURL_LOCK_DATA_COOKIE
CURL_LOCK_DATA_DNS
CURL_LOCK_DATA_LAST
CURL_LOCK_DATA_NONE
CURL_LOCK_DATA_SHARE
CURL_LOCK_DATA_SSL_SESSION
);

sub AUTOLOAD {

    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    ( my $constname = $AUTOLOAD ) =~ s/.*:://;
    return constant( $constname, 0 );
}

1;
__END__

=head1 NAME

WWW::Curl::Share - Perl extension interface for libcurl

=head1 SYNOPSIS

	use WWW::CURL::Share;
	my $curlsh = new WWW::Curl::Share;
	$curlsh->setopt(CURLSHOPT_SHARE, CURL_LOCK_DATA_COOKIE);
	$curlsh->setopt(CURLSHOPT_SHARE, CURL_LOCK_DATA_DNS);
	$curl->setopt(CURLOPT_SHARE, $curlsh);
	$curlsh->setopt(CURLSHOPT_UNSHARE, CURL_LOCK_DATA_COOKIE);
	$curlsh->setopt(CURLSHOPT_UNSHARE, CURL_LOCK_DATA_DNS);

=head1 DESCRIPTION

WWW::Curl::Share is an extension to WWW::Curl::Easy
which makes it possible to use single cookies/dns cache for
several Easy handles.

=head1 METHODS

	$curlsh = new WWW::Curl::Share
		This method constructs a new WWW::Curl::Share object.

	$curlsh->setopt(CURLSHOPT_SHARE, $value );
		Enables share for:
			CURL_LOCK_DATA_COOKIE	use single cookies database
			CURL_LOCK_DATA_DNS	use single DNS cache
	$curlsh->setopt(CURLSHOPT_UNSHARE, $value );
		Disable share for given $value (see CURLSHOPT_SHARE)

	$curlsh->strerror( ErrNo )
		This method returns a string describing the CURLSHcode error 
		code passed in the argument errornum.

	$curl->setopt(CURLOPT_SHARE, $curlsh)
		Attach share object to WWW::Curl::Easy instance

	List of all available options and lock constants:
		CURLSHOPT_LAST
		CURLSHOPT_LOCKFUNC
		CURLSHOPT_NONE
		CURLSHOPT_SHARE
		CURLSHOPT_UNLOCKFUNC
		CURLSHOPT_UNSHARE
		CURLSHOPT_USERDATA
		CURL_LOCK_DATA_CONNECT
		CURL_LOCK_DATA_COOKIE
		CURL_LOCK_DATA_DNS
		CURL_LOCK_DATA_LAST
		CURL_LOCK_DATA_NONE
		CURL_LOCK_DATA_SHARE
		CURL_LOCK_DATA_SSL_SESSION

=head1 AUTHOR

Anton Fedorov (datacompboy <at> mail.ru)

=head1 COPYRIGHT

Copyright (C) 2004 Sebastian Riedel, et al.

You may opt to use, copy, modify, merge, publish, distribute and/or sell
copies of the Software, and permit persons to whom the Software is furnished
to do so, under the terms of the MPL or the MIT/X-derivate licenses. You may
pick one of these licenses.

=head1 SEE ALSO

WWW::Curl, WWW::Curl::Easy, http://curl.haxx.se/
