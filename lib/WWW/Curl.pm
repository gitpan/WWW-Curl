package WWW::Curl;

use strict;
use vars qw(@ISA $VERSION);
use DynaLoader;

BEGIN {
    $VERSION = '3.11';
    @ISA     = qw(DynaLoader);
    __PACKAGE__->bootstrap;
}

1;

__END__

=cut 

=head1 NAME

WWW::Curl - Perl extension interface for libcurl

=head1 SYNOPSIS

    use WWW::Curl;
    print $WWW::Curl::VERSION;

=head1 DESCRIPTION

WWW::Curl is a Perl extension interface for libcurl.
See WWW::Curl::Easy and WWW::Curl::Multi for more documentation.

=head1 AUTHOR

Version 3.10 adds the WWW::Curl::Share interface by Anton Federov
and large file options after a contribution from Mark Hindley.

Version 3.02 adds some backwards compatibility for scripts still using
'WWW::Curl::easy' names.

Version 3.00 adds WWW::Curl::Multi interface, and a new module names
following perl conventions (WWW::Curl::Easy rather than WWW::Curl::easy),
by Sebastian Riedel <sri at cpan.org>

Version 2.00 of WWW::Curl::easy is a renaming of the previous version
(named Curl::easy), to follow CPAN naming guidelines, by Cris Bailiff.

Currently maintained by Cris Bailiff <c.bailiff+curl at devsecure.com>

=head1 COPYRIGHT

Copyright (C) 2003,2004,2005 Cris Bailiff
 
You may opt to use, copy, modify, merge, publish, distribute and/or sell
copies of the Software, and permit persons to whom the Software is furnished
to do so, under the terms of the MPL or the MIT/X-derivate licenses. You may
pick one of these licenses.

=head1 SEE ALSO

WWW::Curl::Easy, WWW::Curl::Multi, http://curl.haxx.se
