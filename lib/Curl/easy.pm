#
# $Id: easy.pm,v 1.3 2003/04/22 13:39:25 crisb Exp $
#
# Backwards compatability package for WWW::Curl::easy
#

package Curl::easy;

use strict;
use vars qw($VERSION @ISA @EXPORT);

$VERSION = '1.36';

require WWW::Curl::easy;
@ISA=qw(WWW::Curl::easy);
@EXPORT=@WWW::Curl::easy::EXPORT;

sub init
{
    return WWW::Curl::easy::init(@_);
}

sub version
{
    return WWW::Curl::easy::version(@_);
}

sub setopt
{
    return WWW::Curl::easy::setopt(@_);
}

sub perform
{
    return WWW::Curl::easy::perform(@_);
}

sub getinfo
{
    return WWW::Curl::easy::getinfo(@_);
}

sub cleanup
{
    return WWW::Curl::easy::cleanup(@_);
}

sub global_cleanup
{
    return WWW::Curl::easy::global_cleanup(@_);
}

1;

__END__

=cut 

=head1 NAME

Curl::easy - Compatability Perl extension interface for libcurl

=head1 SYNOPSIS

	use WWW::Curl::easy;


=head1 DESCRIPTION

This module exists only to provide backwards compatability for existing scripts
using the 'Curl::easy' module, which has now changed name to 'WWW::Curl::easy'.

Don't use this module for new scripts - use 'WWW::Curl::easy' instead.
 
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


