#
# $Id: Curl.pm,v 1.3 2003/04/22 13:39:26 crisb Exp $
#

package WWW::Curl;

use strict;
use vars qw(@ISA $VERSION);
use DynaLoader;

@ISA = qw(DynaLoader);

$VERSION = '2.0';

bootstrap WWW::Curl $VERSION;

1;

__END__

=cut 

=head1 NAME

WWW::Curl - Perl extension interface for libcurl

=head1 SYNOPSIS

	use WWW::Curl::easy;

=head1 DESCRIPTION

This module is a namespace placeholder for a future high level perl-oriented interface to
libcurl. Currently, you need to use the direct libcurl 'easy' interface, by
using the 'WWW::Curl::easy' module.
 
=head1 AUTHOR

Version 2.00 of WWW::Curl::easy is a renaming of the previous version, named Curl::easy,
(also with additional features) to follow CPAN naming guidelines, by Cris Bailiff.

=head1 Copyright

Copyright (C) 2003 Cris Bailiff
 
You may opt to use, copy, modify, merge, publish, distribute and/or sell
copies of the Software, and permit persons to whom the Software is furnished
to do so, under the terms of the MPL or the MIT/X-derivate licenses. You may
pick one of these licenses.

=head1 SEE ALSO

http://curl.haxx.se/
