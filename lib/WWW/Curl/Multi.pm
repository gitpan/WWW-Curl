package WWW::Curl::Multi;

use strict;
use WWW::Curl;

1;
__END__

=head1 NAME

WWW::Curl::Multi - Perl extension interface for libcurl

=head1 SYNOPSIS

	use WWW::CURL::Multi;
	my $curlm = new WWW::Curl::Multi;
	$curlm->add_handle($curl);
	$curlm->perform;
	$curlm->remove_handle($curl);

=head1 DESCRIPTION

WWW::Curl::Multi is an extension to WWW::Curl::Easy
which makes it possible to process multiple easy
handles parallel.

=head1 METHODS

	$curlm = new WWW::Curl::Multi
		This method constructs a new WWW::Curl::Multi object.

	$curlm->add_handle( $curl )
		This method adds a WWW::Curl::Easy object to the multi stack.

	$curlm->perform
		This method parallel perlforms all WWW::Curl::Easy objects
		on the stack.

	*Warning* - this does not perform exactly the
	same functions as the direct libcurl function - for example,
	there's no opportunity to get the fdset back at any time, so
	this interface could change in future as those functions
	are added.

	$curl->remove_handle( $curl )
		This method removes a WWW::Curl::Easy object from the stack.

	*Note* If you want to use several times one set of handles for
	different requests, remove them, change options (f.e. CURLOPT_URL),
	and add back.

	$curlm->strerror( ErrNo )
		This method returns a string describing the CURLMcode error 
		code passed in the argument errornum.

=head1 AUTHOR

Sebastian Riedel (sri@cpan.org)

=head1 COPYRIGHT

Copyright (C) 2004 Sebastian Riedel, et al.

You may opt to use, copy, modify, merge, publish, distribute and/or sell
copies of the Software, and permit persons to whom the Software is furnished
to do so, under the terms of the MPL or the MIT/X-derivate licenses. You may
pick one of these licenses.

=head1 SEE ALSO

WWW::Curl, WWW::Curl::Easy, http://curl.haxx.se/
