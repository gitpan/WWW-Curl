package WWW::Curl::Easy;

use strict;
use warnings;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

$VERSION = '4.11';

require WWW::Curl;
require Exporter;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

@EXPORT = qw(
);

$WWW::Curl::Easy::headers = "";
$WWW::Curl::Easy::content = "";

sub AUTOLOAD {

    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    ( my $constname = $AUTOLOAD ) =~ s/.*:://;
    return constant( $constname, 0 );
}

1;

__END__

Copyright (C) 2000-2005,2008 Daniel Stenberg, Cris Bailiff,
Sebastian Riedel, et al.
 
You may opt to use, copy, modify, merge, publish, distribute and/or sell
copies of the Software, and permit persons to whom the Software is furnished
to do so, under the terms of the MPL or the MIT/X-derivate licenses. You may
pick one of these licenses.
