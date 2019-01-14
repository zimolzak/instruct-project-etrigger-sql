#!/usr/bin/perl -w
use strict;


while(<>){
    my $want_print = 0;
    s/^\s+//;
    s/\r//g;
    tr/[A-Z]/[a-z]/;
    s/  / /g;
    $want_print = 1 if s/.*(\[ord_singh[^ -')]*).*/$1/i;
    s/ //g;
    s/\t//g;
    s/\]//g;
    s/\[//g;
    print if $want_print;
}
