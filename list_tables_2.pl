#!/usr/bin/perl -w
use strict;

my ($filename, $flag) = @ARGV;
#print "$flag\n\n\n"; #deleteme
open my $fh, '<', $filename or die $!;

while(<$fh>){
    my $want_print = 0;
    s/^\s+//;
    s/\r//g;
    tr/[A-Z]/[a-z]/;
    s/  / /g;
    $want_print = 1 if s/.*(\[ord_singh[^ -')]*).*/$1/i;
    $want_print = 1 if s/.*(\[vinci1[^ -')]*).*/$1/i;
    s/ //g;
    s/\t//g;
    s/\]//g;
    s/\[//g;
    if (not defined $flag) {
	print if $want_print;
    }
    elsif ($flag eq '--dst') {
	print if $want_print and /dflt/i;
    }
    elsif ($flag eq '--src') {
	print if $want_print and (/src/i or /vinci/i) ;
    }
}
