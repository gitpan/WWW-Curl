# Makefile.PL for Perl extension WWW::Curl::easy.
# Check out the file README for more info.

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#
# This utility helper generates the constants function from curl.h
#
# It is normally only used by the maintainer, but if you're curl is older
# or missing some constants, you can delete curlopt-constants.c and re-run 'perl Makefile.PL'
#

#
# You may need to specify where to find curl.h on your platform
# These are guesses only
#

my @includes = qw(
    /usr/include
    /usr/local/curl/include
    /usr/local/include/curl
    ../../include
    ../curl/include
    C:\\INCLUDE\\CURL
);

#
# Get curl to tell us where it is, if we can. May well not find anything on Windows
#
my $cflags = `curl-config --cflags`;
my $lflags = `curl-config --libs`;

# can't find link flags, make some guesses
if (!defined($lflags)) {
    $lflags="-lcurl";
    # Windows version of libcurl - not widely tested, feedback welcome!
    if ($^O eq 'MSWin32') {
	foreach my $try (@includes) {
	    if (-f $try . '\lib\libcurl_imp.lib') {
		$lflags = $try . '\lib\libcurl_imp.lib' unless(-f $lflags);
		last;
		}
	}
        $lflags="libcurl.lib" unless ($lflags);
    }
    print "Guessing your linker flags as: $lflags\n";
}

if ($lflags !~ m/curl/i) {
    # curl7.8 doesn't include itself in the link flags
    $lflags .= " -lcurl"
}


my ($flag) = ($cflags =~ m/-I(\S+)/);

if (defined $flag) {
    unshift @includes, $flag;    # first guess
}

# try the path given on the command line, if any
if (defined($ARGV[0])) {
    unshift @includes, $ARGV[0];
};

my $curl_d = "";
my $curl_h;

# otherwise try a list of common locations
foreach my $try (@includes) {
    if (-f $try . "/curl/curl.h") {
        $curl_d = $try;
        $curl_h = $try . "/curl/curl.h";
        last;
    }
}

if (!defined($curl_h)) {
    die "Cannot find curl.h - cannot build constants files  - see Makefile.PL";
} else {
    $curl_d = "-I" . $curl_d;
    print "Found curl.h in $curl_h\n";
    open(CURL_H, "<" . $curl_h) or die "Can't open curl.h\n";
    my %cinit_types;
    my %cinit_codes;
    my @curlinfo;
    my @curlshopt;
    my @curllockopt;
    while (<CURL_H>) {
        if ($_ =~ m/CINIT\(/ and $_ !~ m/#/) {
            my ($option, $type, $code) =
                m/.*CINIT\((\w*)\s*,\s*(\w+)\s*,\s*(\d+).*/;
            $cinit_types{$option} = $type;
            $cinit_codes{$option} = $code;
        } elsif ($_ =~ m/^\s*(CURLINFO_\w+)/) {
            push @curlinfo, $1;
        } elsif ($_ =~ m/^\s*(CURLSHOPT_\w+)/) {
            push @curlshopt, $1;
        } elsif ($_ =~ m/^\s*(CURL_LOCK_DATA_\w+)/) {
            push @curllockopt, $1;
        }

    }
    close(CURL_H);

    # some things are ifdefed out...
    foreach my $ifdef0 (qw(FLAGS PROGRESSMODE MOREDOCS)) {
        delete $cinit_types{$ifdef0};
        delete $cinit_codes{$ifdef0};
    }

    print "Building curlopt-constants.c for your libcurl version\n";

    open(CURL_XS, ">curlopt-constants.c")
        or die "Can't write curlopt-constants.c\n";

    # boilerplate xs constant function here
    print CURL_XS <<HERE
static int
constant(char *name, int arg)
{
    errno = 0;
    if (strncmp(name, "CURLINFO_", 9) == 0) {
        name += 9;
    switch (*name) {
HERE
        ;
    foreach my $next_initial ('A' .. 'Z') {
        print CURL_XS "        case '$next_initial':\n";
        my $count = 0;
        foreach my $curlinfo_name (sort @curlinfo) {
            my $initial = substr($curlinfo_name, 9, 1);
            my $option = substr($curlinfo_name, 9);
            if ($next_initial eq $initial) {

                print CURL_XS
"            if (strEQ(name, \"$option\")) return CURLINFO_$option;\n";

                $count++;
            }
        }
        if ($count or $next_initial eq 'Z') {
            print CURL_XS "            break;\n";
        }
    }

    print CURL_XS "    };\n";
    print CURL_XS "    }\n";

	# CURLOPT_
	print CURL_XS <<HERE2

    if (strncmp(name, "CURLOPT_", 8) == 0) {
        name += 8;
        switch (*name) {
HERE2
        ;

    foreach my $next_initial ('A' .. 'Z') {
        print CURL_XS "        case '$next_initial':\n";
        my $count = 0;
        foreach my $option (sort keys %cinit_types) {
            my $initial = substr($option, 0, 1);
            if ($next_initial eq $initial) {

                print CURL_XS
"            if (strEQ(name, \"$option\")) return CURLOPT_$option;\n";

                $count++;
            }
        }
        if ($count or $next_initial eq 'Z') {
            print CURL_XS "            break;\n";
        }
    }

    print CURL_XS "    };\n";
    print CURL_XS "    }\n";

	# CURLSHOPT_
	print CURL_XS <<HERE2

    if (strncmp(name, "CURLSHOPT_", 10) == 0) {
        name += 10;
        switch (*name) {
HERE2
        ;

    foreach my $next_initial ('A' .. 'Z') {
        print CURL_XS "        case '$next_initial':\n";
        my $count = 0;
        foreach my $option (sort @curlshopt) {
            my $initial = substr($option, 10, 1);
            if ($next_initial eq $initial) {
				my $optsuff = substr($option, 10);
                print CURL_XS
"            if (strEQ(name, \"$optsuff\")) return $option;\n";
				
                $count++;
            }
        }
        if ($count or $next_initial eq 'Z') {
            print CURL_XS "            break;\n";
        }
    }

    print CURL_XS "    };\n";
    print CURL_XS "    }\n";

	# CURL_LOCK_DATA_
	print CURL_XS <<HERE2
    if (strncmp(name, "CURL_LOCK_DATA_", 15) == 0) {
        name += 15;
        switch (*name) {
HERE2
        ;

    foreach my $next_initial ('A' .. 'Z') {
        print CURL_XS "        case '$next_initial':\n";
        my $count = 0;
        foreach my $option (sort @curllockopt) {
            my $initial = substr($option, 15, 1);
            if ($next_initial eq $initial) {
				my $optsuff = substr($option, 15);
                print CURL_XS
"            if (strEQ(name, \"$optsuff\")) return $option;\n";
				
                $count++;
            }
        }
        if ($count or $next_initial eq 'Z') {
            print CURL_XS "            break;\n";
        }
    }

    print CURL_XS "    };\n";
    print CURL_XS "    }\n";

    print CURL_XS <<HERE

    errno = EINVAL;
    return 0;
}
HERE
        ;

    close(CURL_XS);

    print "Building Easy.pm constants for your libcurl version\n";

    open(EASY_PM,    ">lib/WWW/Curl/Easy.pm")    or die "Can't create lib/WWW/Curl/Easy.pm\n";
    open(EASY_PM_IN, "Easy.pm.in") or die "Can't read Easy.pm.in\n";
    while (my $line = <EASY_PM_IN>) {
        if ($line !~ m/^\@CURLOPT_INCLUDE\@/) {
			print EASY_PM $line;
        } else {
            foreach my $option (sort keys %cinit_types) {
                next unless $option; # an empty CURLOPT_
                print EASY_PM "CURLOPT_$option\n";
            }
            foreach my $option (sort @curlinfo) {
                print EASY_PM $option . "\n";
            }
        }
    }
    close(EASY_PM);
    close(EASY_PM_IN);

	print "Building Share.pm constants for your libcurl version\n";

    open(SHARE_PM,   ">lib/WWW/Curl/Share.pm")    or die "Can't create lib/WWW/Curl/Share.pm\n";
    open(SHARE_PM_IN, "Share.pm.in") or die "Can't read Share.pm.in\n";
    while (my $line = <SHARE_PM_IN>) {
        if ($line !~ m/^(.*?)\@CURLSHOPT_INCLUDE\@/) {
            print SHARE_PM $line;
        } else {
            foreach my $option (sort @curlshopt) {
                print SHARE_PM $1 . $option . "\n";
            }
            foreach my $option (sort @curllockopt) {
                print SHARE_PM $1 . $option . "\n";
            }
        }
    }
    close(SHARE_PM);
    close(SHARE_PM_IN);
}

#
# Now write the makefile
#
WriteMakefile(
    'NAME'         => 'WWW::Curl',
    'VERSION_FROM' => 'lib/WWW/Curl.pm',      # finds $VERSION
    'LIBS'         => $lflags,        # e.g., '-lm'
    'INC'          => $curl_d,        # e.g., '-I/usr/include/other'
    'clean' => { FILES => "head.out body.out" }
);

