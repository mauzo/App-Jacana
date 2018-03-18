#!/usr/bin/perl

use warnings;
use strict;

use Config;

# XXX we aren't necessarily installing here...
my $bin = $Config{installsitescript};

open my $F, ">", $ARGV[0];
print $F <<DESKTOP;
[Desktop Entry]
Version=1.0
Name=Jacana
Icon=Jacana
Type=Application
Terminal=false
Exec=$bin/jacana %U
DESKTOP

close $F;
